output "dns_publica" {
    value = "http://${aws_instance.mi_servidor.public_dns}:8080"
    description = "DNS publica del servidor"
}