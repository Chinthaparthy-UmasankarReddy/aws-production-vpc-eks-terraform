provider "aws" {
  region = "ap-south-1"
}

# The S3 Bucket to store all .tfstate files
resource "aws_s3_bucket" "terraform_state" {
  bucket = "jiomart-terraform-state-2026-uma" # Must be globally unique
  
  lifecycle {
    prevent_destroy = false # true Production Grade: Never accidentally delete your state
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled" # Allows you to roll back state if it gets corrupted
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "jiomart-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
