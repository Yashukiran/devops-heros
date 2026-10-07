# Single-host deployment target: an EC2 instance in the default VPC that runs the
# same images CI pushed to GHCR (the Kubernetes/Helm path is used for the cluster).
data "aws_vpc" "default" {
  default = true
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "app" {
  name        = "session21-task-tracker"
  description = "Task Tracker UI (8080) and API (8000)"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  for_each = { for pair in setproduct(var.allowed_cidrs, [8000, 8080]) : "${pair[0]}-${pair[1]}" => pair }

  security_group_id = aws_security_group.app.id
  cidr_ipv4         = each.value[0]
  from_port         = each.value[1]
  to_port           = each.value[1]
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app.id]

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y docker
    systemctl enable --now docker
    docker network create app
    docker run -d --name backend --network app --restart unless-stopped -p 8000:8000 -e ENVIRONMENT=aws-ec2 ${var.api_image}
    docker run -d --name frontend --network app --restart unless-stopped -p 8080:8080 -e BACKEND_HOST=backend ${var.ui_image}
  EOF

  user_data_replace_on_change = true

  tags = { Name = "session21-task-tracker" }
}
