variable "aws_region" {
  description = "AWS region where the S3 bucket is created."
  type        = string
  default     = "ap-south-1"
}

variable "bucket_prefix" {
  description = "Prefix for the bucket name. A random suffix is added because S3 bucket names are globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,40}$", var.bucket_prefix))
    error_message = "bucket_prefix must be 3-41 characters: lowercase letters, numbers and hyphens."
  }
}

variable "environment" {
  description = "Environment name used in tags."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag value."
  type        = string
}

variable "enable_versioning" {
  description = "Keep previous versions of objects."
  type        = bool
  default     = true
}
