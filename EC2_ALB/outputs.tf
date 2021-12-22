output "dns_publica_sv_1" {
  value       = "http://${aws_instance.new_server_1.public_dns}:${var.puerto_servidor}"
  description = "DNS publica del servidor"
}

output "dns_publica_sv_2" {
  value       = "http://${aws_instance.new_server_2.public_dns}:${var.puerto_servidor}"
  description = "DNS publica del servidor"
}

output "dns_publica_lb" {
  value       = "http://${aws_lb.alb.dns_name}:${var.puerto_loadbalancer}"
  description = "DNS publica del load balancer"
}