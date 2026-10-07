# Web security group: HTTP in, everything out.
# No SSH rule at all – the instance is configured entirely by user_data,
# so port 22 never has to be opened to the internet.
resource "aws_security_group" "web" {
  name        = "${var.project}-web-sg"
  description = "Allow HTTP to the Session 19 web server"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project}-web-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = toset(var.allowed_http_cidrs)

  security_group_id = aws_security_group.web.id
  description       = "HTTP"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.web.id
  description       = "All outbound (package installs, updates)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
