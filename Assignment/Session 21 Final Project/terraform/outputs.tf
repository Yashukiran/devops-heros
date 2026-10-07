output "frontend_url" {
  value = "http://${aws_instance.app.public_ip}:8080"
}

output "api_docs_url" {
  value = "http://${aws_instance.app.public_ip}:8000/docs"
}
