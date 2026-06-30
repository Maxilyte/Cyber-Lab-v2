# backend.tf
# Remote state infrastructure for Cyber-Lab-v2
# S3 bucket stores the Terraform state file
# DynamoDB table provides state locking to prevent concurrent applies

#checkov:skip=CKV_AWS_144:Cross-region replication not required for lab. Single-region deployment acceptable at this scale.
#checkov:skip=CKV_AWS_145:KMS CMK not required for lab. AES256 with AWS-managed keys provides sufficient protection at this scale.
#checkov:skip=CKV2_AWS_61:Lifecycle policy not configured. State file versions managed manually in lab environment.
#checkov:skip=CKV2_AWS_62:S3 event notifications not required for lab. No downstream processing pipeline exists.
resource "aws_s3_bucket" "terraform_state" {
  bucket = "cyber-lab-v2-tfstate-689546299913"

  tags = {
    Name        = "Terraform State"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Separate bucket to receive access logs from the state bucket.
# Logs cannot be written to the bucket they are logging.
#checkov:skip=CKV_AWS_144:Cross-region replication not required for lab environment.
#checkov:skip=CKV_AWS_145:KMS CMK not required for lab. AES256 sufficient at this scale.
#checkov:skip=CKV2_AWS_61:Lifecycle policy not configured. Log retention managed manually in lab.
#checkov:skip=CKV2_AWS_62:S3 event notifications not required for lab.
#checkov:skip=CKV_AWS_18:Access logging not enabled on logging bucket itself. Acceptable for lab to avoid circular dependency.
resource "aws_s3_bucket" "terraform_state_logs" {
  bucket = "cyber-lab-v2-tfstate-logs-689546299913"

  tags = {
    Name        = "Terraform State Access Logs"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enables server access logging on the state bucket.
# Every request against the state bucket is recorded in the logs bucket.
resource "aws_s3_bucket_logging" "terraform_state" {
  bucket        = aws_s3_bucket.terraform_state.id
  target_bucket = aws_s3_bucket.terraform_state_logs.id
  target_prefix = "state-access-logs/"
}

#checkov:skip=CKV_AWS_119:KMS CMK not required for lab. DynamoDB encrypted at rest with AWS-managed keys. CMK overhead not justified at this scale.
#checkov:skip=CKV_AWS_28:Point-in-time recovery not required. Table holds transient lock entries only. A lost lock is manually recoverable.
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "cyber-lab-v2-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock"
    Environment = "lab"
    ManagedBy   = "terraform"
    Project     = "Cyber-Lab-v2"
  }
}