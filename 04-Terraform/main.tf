# main.tf
# Core infrastructure for Cyber-Lab-v2
# VPC and supporting resources

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket       = "cyber-lab-v2-tfstate-689546299913"
    key          = "terraform.tfstate"
    region       = "ca-central-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "cyber-lab-v2-vpc"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# Overrides the permissive AWS default security group with zero rules.
# Any resource accidentally placed in the default SG will have no
# connectivity, making the mistake immediately visible.
resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "cyber-lab-v2-default-sg-restricted"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

# S3 bucket to receive VPC flow logs.
# Flow logs are written by the AWS Flow Logs service, not terraform-runner,
# so a bucket policy granting that service write access is required.
#checkov:skip=CKV_AWS_144:Cross-region replication not required for lab environment.
#checkov:skip=CKV_AWS_145:KMS CMK not required for lab. AES256 sufficient at this scale.
#checkov:skip=CKV2_AWS_61:Lifecycle policy not configured. Flow logs managed manually in lab.
#checkov:skip=CKV2_AWS_62:S3 event notifications not required for lab.
#checkov:skip=CKV_AWS_18:Access logging not enabled on flow logs bucket. Acceptable for lab.
resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket = "cyber-lab-v2-flow-logs-689546299913"

  tags = {
    Name        = "VPC Flow Logs"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

resource "aws_s3_bucket_versioning" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy granting the AWS Flow Logs service permission to write
# log files to this bucket. Without this, flow log delivery is denied.
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFlowLogsWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.vpc_flow_logs.arn}/flow-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowFlowLogsAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.vpc_flow_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# VPC flow log resource.
# Captures ALL traffic metadata (ACCEPT and REJECT) for the VPC.
# REJECT records are often more valuable than ACCEPT for security analysis.
resource "aws_flow_log" "main" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  iam_role_arn         = null
  log_destination      = "${aws_s3_bucket.vpc_flow_logs.arn}/flow-logs/"
  log_destination_type = "s3"

  tags = {
    Name        = "cyber-lab-v2-vpc-flow-logs"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}