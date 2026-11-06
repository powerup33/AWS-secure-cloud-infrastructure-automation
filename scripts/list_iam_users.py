
import boto3
from datetime import datetime, timezone, timedelta
from pprint import pprint

# ==========================================
# AWS IAM SECURITY AUDIT
# ==========================================

# Connect to AWS IAM
iam = boto3.client('iam')

# Set the 90-day cutoff date
cutoff_date = datetime.now(timezone.utc) - timedelta(days=90)

# Retrieve all IAM users using pagination
paginator = iam.get_paginator('list_users')

# Audit each IAM user
for page in paginator.paginate():
    for user in page['Users']:
        username = user['UserName']

        print("\n===================================")
        print("IAM USER:", username)
        print("Created:", user['CreateDate'])

        # ======================================
        # CHECK ACCESS KEYS
        # ======================================

        keys = iam.list_access_keys(UserName=username)

        print("\nNumber of access keys:", len(keys['AccessKeyMetadata']))

        # Examine each access key
        for key in keys['AccessKeyMetadata']:
            key_id = key['AccessKeyId']
            created = key['CreateDate']
            status = key['Status']

            print("\nAccess Key Status:", status)
            print("Key Created:", created)

            # Check whether key is older than 90 days
            if created < cutoff_date:
                print("WARNING: Access key is older than 90 days.")
            else:
                print("Access key is less than 90 days old.")

            # Retrieve last-used information
            last_used = iam.get_access_key_last_used(
                AccessKeyId=key_id
            )

            last_used_date = last_used['AccessKeyLastUsed'].get('LastUsedDate')

            if last_used_date:
                print("Last Used:", last_used_date)
            else:
                print("Last Used: Never recorded")

        # ======================================
        # CHECK MANAGED POLICIES
        # ======================================

        policies = iam.list_attached_user_policies(
            UserName=username
        )

        print("\nAttached Managed Policies:")

        for policy in policies['AttachedPolicies']:
            print("\nPolicy Name:", policy['PolicyName'])
            print("Policy ARN:", policy['PolicyArn'])

            # Retrieve policy details
            policy_details = iam.get_policy(
                PolicyArn=policy['PolicyArn']
            )

            version_id = policy_details['Policy']['DefaultVersionId']

            policy_document = iam.get_policy_version(
                PolicyArn=policy['PolicyArn'],
                VersionId=version_id
            )

            print("\nPolicy Permissions:")
            pprint(policy_document['PolicyVersion']['Document'])

        # ======================================
        # CHECK INLINE POLICIES
        # ======================================

        inline_policies = iam.list_user_policies(
            UserName=username
        )

        print("\nInline Policies:")

        if inline_policies['PolicyNames']:
            for policy_name in inline_policies['PolicyNames']:
                print("Policy Name:", policy_name)
        else:
            print("No inline policies found.")

        print("\n===================================")
