import boto3

iam = boto3.client("iam")

# Check whether MFA is enabled on the AWS root account
account_summary = iam.get_account_summary()
root_mfa = account_summary["SummaryMap"].get("AccountMFAEnabled", 0)

print("\n===================================")
print("AWS IAM MFA SECURITY AUDIT")
print("===================================")

print(f"\nRoot account MFA enabled: {'YES' if root_mfa == 1 else 'NO'}")

# Retrieve all IAM users
paginator = iam.get_paginator("list_users")
users = []

for page in paginator.paginate():
    users.extend(page["Users"])

if not users:
    print("\nNo IAM users found.")

# Check each IAM user's assigned MFA devices
for user in users:
    username = user["UserName"]

    mfa_devices = iam.list_mfa_devices(UserName=username)["MFADevices"]

    mfa_enabled = len(mfa_devices) > 0

    print("\n-----------------------------------")
    print(f"IAM User: {username}")
    print(f"MFA Enabled: {'YES' if mfa_enabled else 'NO'}")

print("\n===================================")
print("MFA AUDIT COMPLETE")
print("===================================")