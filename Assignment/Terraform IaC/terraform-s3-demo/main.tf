# random 4-byte suffix -> e.g. "yashukiran-session18-3f9a1c2e"
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "demo" {
  bucket        = "${var.bucket_prefix}-${random_id.suffix.hex}"
  force_destroy = true # lets `terraform destroy` remove the bucket even if it has objects

  tags = {
    Name = "${var.bucket_prefix}-${random_id.suffix.hex}"
  }
}

# keep old versions of every object (protects against accidental overwrite/delete)
resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# encrypt every object at rest by default
resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# the bucket can never be made public by mistake
resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# a sample object, so the bucket is not empty
resource "aws_s3_object" "readme" {
  bucket       = aws_s3_bucket.demo.id
  key          = "hello.txt"
  content      = "Created by Terraform for DevOps Heroes Session 18 (${var.owner})"
  content_type = "text/plain"
}
