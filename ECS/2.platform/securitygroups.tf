resource "aws_security_group" "ecs_alb_security_group" {
  name        = var.ecs_cluster_name
  description = "Security group for ALB"
  vpc_id      = data.terraform_remote_state.infrastructure.outputs.vpc_id

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["${var.internet_cidr_blocks}"]
  }

  egress {
    cidr_blocks = ["${var.internet_cidr_blocks}"]
    from_port   = 0 //El puerto 0 y el protocolo -1 define que todo el trafico es permitido
    protocol    = "-1"
    to_port     = 0
  }
}