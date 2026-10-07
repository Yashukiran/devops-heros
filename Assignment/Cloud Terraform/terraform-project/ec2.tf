# latest Amazon Linux 2023 AMI for this region (no hard-coded AMI IDs)
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "web" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  # IMDSv2 only (blocks SSRF-style metadata theft)
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  # install nginx and publish a page that shows where it is running
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
    md() { curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/$1; }
    cat > /usr/share/nginx/html/index.html <<HTML
    <html><head><title>Session 19 - Terraform</title></head>
    <body style="font-family:sans-serif;background:#0d1117;color:#e6edf3;padding:40px">
      <h1>Deployed with Terraform &#x2705;</h1>
      <p>DevOps Heroes &middot; Session 19 &middot; ${var.owner}</p>
      <ul>
        <li>Instance: $(md instance-id) ($(md instance-type))</li>
        <li>Availability Zone: $(md placement/availability-zone)</li>
        <li>Private IP: $(md local-ipv4) &middot; Public IP: $(md public-ipv4)</li>
        <li>VPC CIDR: ${var.vpc_cidr} &middot; Subnet: ${var.public_subnet_cidr}</li>
      </ul>
    </body></html>
    HTML
    systemctl enable --now nginx
  EOF

  user_data_replace_on_change = true

  # the route to the internet must exist before the instance boots, or dnf cannot reach the repos
  depends_on = [aws_route_table_association.public]

  tags = { Name = "${var.project}-web" }
}
