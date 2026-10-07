variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Name prefix for all resources."
  type        = string
  default     = "session19"
}

variable "owner" {
  description = "Owner tag value."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidr" {
  description = "CIDR block of the public subnet (must be inside vpc_cidr)."
  type        = string
  default     = "10.20.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type (t3.micro is Free Tier eligible in ap-south-1)."
  type        = string
  default     = "t3.micro"
}

variable "allowed_http_cidrs" {
  description = "Who may reach the web server on port 80."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
