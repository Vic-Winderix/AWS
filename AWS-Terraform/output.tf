# Publieke IP van de API instance
output "api_public_ip" {
  description = "Publieke IP adres van de API instance"
  value       = aws_instance.api.public_ip
}

# Publieke IP van de APP instance
output "app_public_ip" {
  description = "Publieke IP adres van de APP instance"
  value       = aws_instance.app.public_ip
}