resource "random_id" "suffix" {
  byte_length = 4
}

# private, encrypted, versioned bucket for the project's artifacts/logs
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project}-artifacts-${random_id.suffix.hex}"
  force_destroy = true

  tags = { Name = "${var.project}-artifacts" }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# record what was deployed – depends on the EC2 instance (implicit dependency via its attributes)
resource "aws_s3_object" "deployment_info" {
  bucket       = aws_s3_bucket.artifacts.id
  key          = "deployments/web-server.json"
  content_type = "application/json"
  content = jsonencode({
    instance_id   = aws_instance.web.id
    instance_type = aws_instance.web.instance_type
    ami           = aws_instance.web.ami
    public_ip     = aws_instance.web.public_ip
    subnet_id     = aws_subnet.public.id
    vpc_id        = aws_vpc.main.id
  })
}
