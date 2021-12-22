output "dns_publica_sv_1" {
  value       = "http://${aws_instance.new_server_1.public_dns}:8080"
  description = "DNS publica del servidor"
}

output "dns_publica_sv_2" {
  value       = "http://${aws_instance.new_server_2.public_dns}:8080"
  description = "DNS publica del servidor"
}

output "dns_publica_lb" {
  value       = "http://${aws_lb.alb.dns_name}:80"
  description = "DNS publica del load balancer"
}