# Simple IAM Role for providing Read Only Permission to EKS

# Create the IAM Role
aws iam create-role --role-name EKSReadOnlyRole --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "eks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}'

# Create RadOnly policy
aws iam create-policy --policy-name EKSReadOnlyPolicy --policy-document file://EKSReadOnlyPolicy.json

# Attach the Read-Only Policy
aws iam attach-role-policy --role-name EKSReadOnlyRole --policy-arn arn:aws:iam::<your-account-id>:policy/EKSReadOnlyPolicy

# Verify the Policy Attachment
aws iam list-attached-role-policies --role-name EKSReadOnlyRole
