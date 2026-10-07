variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "owner" {
  type    = string
  default = "Yashukiran"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "allowed_cidrs" {
  description = "Who may reach the frontend (8080) and API (8000)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "api_image" {
  type    = string
  default = "ghcr.io/yashukiran/session21-task-tracker-api:1.0.0"
}

variable "ui_image" {
  type    = string
  default = "ghcr.io/yashukiran/session21-task-tracker-ui:1.0.0"
}
