"""
AWS IAM Security Audit (read-only)

Checks the account and every IAM user for:
  - Root account MFA
  - Access keys older than 90 days
  - Active access keys that were never used, or unused for 90+ days
  - Console access without MFA
  - Overly broad permissions (wildcard actions or resources) in attached
    managed policies and inline policies

If an API call is denied (for example by a service control policy), that
check is reported as SKIPPED and the audit continues, so one denied call
never stops the whole run.

Makes only read (List/Get) API calls.
"""

import boto3
from botocore.exceptions import ClientError
from datetime import datetime, timezone, timedelta

KEY_MAX_AGE_DAYS = 90

iam = boto3.client("iam")
cutoff_date = datetime.now(timezone.utc) - timedelta(days=KEY_MAX_AGE_DAYS)

# Findings are stored as (severity, username, message) for the summary
findings = []
# Checks that could not run, stored as (username, check name, error code)
skipped = []


def add_finding(username, severity, message):
    findings.append((severity, username, message))
    print(f"  [{severity}] {message}")


def run_check(username, check_name, check_function, *args):
    """Run one check. If AWS denies a call, log it and keep going."""
    try:
        check_function(*args)
    except ClientError as error:
        code = error.response["Error"]["Code"]
        skipped.append((username, check_name, code))
        print(f"  [SKIPPED] {check_name}: {code}")


def check_root_mfa():
    # Root account MFA is one of the most important controls in AWS
    summary = iam.get_account_summary()["SummaryMap"]
    if summary.get("AccountMFAEnabled", 0) == 1:
        print("  Root account MFA: enabled")
    else:
        add_finding("ROOT", "HIGH", "Root account does not have MFA enabled")


def check_access_keys(username):
    keys = iam.list_access_keys(UserName=username)["AccessKeyMetadata"]
    print(f"  Access keys: {len(keys)}")

    for key in keys:
        key_id = key["AccessKeyId"]
        masked = "..." + key_id[-4:]  # mask the ID so output is safe to share
        is_active = key["Status"] == "Active"

        if is_active and key["CreateDate"] < cutoff_date:
            add_finding(username, "MEDIUM",
                        f"Key {masked} is older than {KEY_MAX_AGE_DAYS} days")

        last_used = iam.get_access_key_last_used(AccessKeyId=key_id)
        last_used_date = last_used["AccessKeyLastUsed"].get("LastUsedDate")

        if is_active and last_used_date is None:
            add_finding(username, "LOW", f"Active key {masked} has never been used")
        elif is_active and last_used_date < cutoff_date:
            add_finding(username, "MEDIUM",
                        f"Active key {masked} unused for {KEY_MAX_AGE_DAYS}+ days")


def check_mfa(username):
    mfa_devices = iam.list_mfa_devices(UserName=username)["MFADevices"]

    # A login profile means the user can sign in to the AWS console.
    # None means we could not determine it (for example, access was denied).
    try:
        iam.get_login_profile(UserName=username)
        has_console_access = True
    except iam.exceptions.NoSuchEntityException:
        has_console_access = False
    except ClientError as error:
        has_console_access = None
        code = error.response["Error"]["Code"]
        skipped.append((username, "console access check", code))
        print(f"  [SKIPPED] console access check: {code}")

    if mfa_devices:
        print(f"  MFA devices: {len(mfa_devices)}")
    elif has_console_access:
        add_finding(username, "HIGH", "Console access enabled but no MFA device")
    elif has_console_access is None:
        add_finding(username, "MEDIUM",
                    "No MFA device, and console access could not be checked")
    else:
        print("  No MFA device (user has no console access, programmatic only)")


def check_policy_document(username, policy_name, document):
    """Flag wildcard permissions in a policy document."""
    statements = document.get("Statement", [])
    if isinstance(statements, dict):
        statements = [statements]

    for statement in statements:
        if statement.get("Effect") != "Allow":
            continue

        actions = statement.get("Action", [])
        resources = statement.get("Resource", [])
        if isinstance(actions, str):
            actions = [actions]
        if isinstance(resources, str):
            resources = [resources]

        if "*" in actions and "*" in resources:
            add_finding(username, "HIGH",
                        f"Policy '{policy_name}' allows all actions on all resources")
        elif "*" in actions or any(a.endswith(":*") for a in actions):
            add_finding(username, "MEDIUM",
                        f"Policy '{policy_name}' uses wildcard actions, review scope")
        elif "*" in resources:
            add_finding(username, "LOW",
                        f"Policy '{policy_name}' applies to all resources, review scope")


def check_policies(username):
    # Attached managed policies
    attached = iam.list_attached_user_policies(UserName=username)["AttachedPolicies"]
    print(f"  Attached managed policies: {len(attached)}")

    for policy in attached:
        arn = policy["PolicyArn"]
        version_id = iam.get_policy(PolicyArn=arn)["Policy"]["DefaultVersionId"]
        document = iam.get_policy_version(
            PolicyArn=arn, VersionId=version_id
        )["PolicyVersion"]["Document"]
        check_policy_document(username, policy["PolicyName"], document)

    # Inline policies (contents are inspected, not just listed)
    inline_names = iam.list_user_policies(UserName=username)["PolicyNames"]
    print(f"  Inline policies: {len(inline_names)}")

    for name in inline_names:
        document = iam.get_user_policy(
            UserName=username, PolicyName=name
        )["PolicyDocument"]
        check_policy_document(username, name, document)


def main():
    print("ROOT ACCOUNT")
    run_check("ROOT", "root MFA check", check_root_mfa)

    paginator = iam.get_paginator("list_users")

    for page in paginator.paginate():
        for user in page["Users"]:
            username = user["UserName"]
            print(f"\nIAM USER: {username}  (created {user['CreateDate']:%Y-%m-%d})")
            run_check(username, "access key check", check_access_keys, username)
            run_check(username, "MFA check", check_mfa, username)
            run_check(username, "policy check", check_policies, username)

    # Summary
    print("\n===================================")
    print("AUDIT SUMMARY")
    print("===================================")
    for severity in ("HIGH", "MEDIUM", "LOW"):
        count = sum(1 for f in findings if f[0] == severity)
        print(f"{severity}: {count}")

    if not findings:
        print("No findings.")

    if skipped:
        print(f"\nChecks skipped (access denied or error): {len(skipped)}")
        for username, check_name, code in skipped:
            print(f"  - {username}: {check_name} ({code})")


if __name__ == "__main__":
    main()