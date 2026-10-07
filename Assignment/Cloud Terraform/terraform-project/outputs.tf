output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet."
  value       = aws_subnet.public.id
}

output "availability_zone" {
  description = "AZ of the public subnet."
  value       = aws_subnet.public.availability_zone
}

output "security_group_id" {
  description = "ID of the web security group."
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance."
  value       = aws_instance.web.public_ip
}

output "website_url" {
  description = "URL of the nginx page served by the instance."
  value       = "http://${aws_instance.web.public_ip}"
}

output "s3_bucket_name" {
  description = "Name of the artifacts bucket."
  value       = aws_s3_bucket.artifacts.bucket
}

output "deployment_record" {
  description = "S3 URI of the deployment record."
  value       = "s3://${aws_s3_bucket.artifacts.bucket}/${aws_s3_object.deployment_info.key}"
}
