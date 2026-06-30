# iam.tf
# Least-privilege IAM policy for terraform-runner service account
# Policy actions derived from AWS CloudTrail activity analysis (June 7 - June 30, 2026)
# Replaces AdministratorAccess with scoped permissions based on actual usage

data "aws_iam_user" "terraform_runner" {
  user_name = "teraform-runner"
}

data "aws_iam_policy_document" "terraform_runner" {

  # Read-only actions that require Resource: *
  # These cannot be scoped to specific resources in IAM
  statement {
    sid    = "ReadOnlyGlobal"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeTags",
      "cloudtrail:LookupEvents",
      "ec2:DescribeFlowLogs",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeTags",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNatGateways",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeImages",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribePrefixLists",
      "ecs:ListClusters",
      "ecs:ListContainerInstances",
      "ecs:ListServices",
      "ecs:ListTaskDefinitions",
      "ecs:ListTasks",
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLogging",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketPolicy",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }

  # DynamoDB management
  # Scoped to the state lock table only
  statement {
    sid    = "DynamoDBStateLock"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTagsOfResource",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:UpdateTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:ca-central-1:689546299913:table/cyber-lab-v2-tfstate-lock"]
  }

  # EC2 write actions
  # VPC, security groups, flow logs, tags
  statement {
    sid    = "EC2WriteActions"
    effect = "Allow"
    actions = [
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:ModifySubnetAttribute",
      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:DeleteNatGateway",
      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
      "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
      "ec2:CreateFlowLogs",
      "ec2:DeleteFlowLogs",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:StopInstances",
      "ec2:StartInstances",
      "ec2:ModifyInstanceAttribute"
    ]
    resources = ["*"]
  }

  # S3 write actions
  statement {
    sid    = "S3WriteActions"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:PutBucketAcl",
      "s3:PutBucketCORS",
      "s3:PutBucketLogging",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketTagging",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["*"]
  }

  # IAM - CreateServiceLinkedRole only
  # Required for AWS services that need to create service-linked roles
  statement {
    sid    = "IAMServiceLinkedRole"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:GetUser",
      "iam:ListAttachedUserPolicies",
      "iam:GetPolicy",
      "iam:GetPolicyVersion"
    ]
    resources = ["*"]
  }
}

# Create the policy in AWS
resource "aws_iam_policy" "terraform_runner" {
  name        = "cyber-lab-v2-terraform-runner-policy"
  description = "Least-privilege policy for terraform-runner. Based on CloudTrail activity analysis June 7-30 2026. Replaces AdministratorAccess."
  policy      = data.aws_iam_policy_document.terraform_runner.json

  tags = {
    Name        = "cyber-lab-v2-terraform-runner-policy"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# Attach the least-privilege policy to terraform-runner
resource "aws_iam_user_policy_attachment" "terraform_runner_least_privilege" {
  user       = data.aws_iam_user.terraform_runner.user_name
  policy_arn = aws_iam_policy.terraform_runner.arn
}