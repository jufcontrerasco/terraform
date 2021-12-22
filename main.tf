provider "aws" { // Provider para enlazar con la cuenta de AWS
  region  = local.region
  profile = "devfelipe"
}
# -----------------------------------------------
# Data source que obtiene el id del AZ us-east-1a
# -----------------------------------------------
data "aws_subnet" "az_a" { //DataSource
  availability_zone = "${local.region}a"
}
# -----------------------------------------------
# Data source que obtiene el id del AZ us-east-1b
# -----------------------------------------------
data "aws_subnet" "az_b" { //DataSource
  availability_zone = "${local.region}b"
}
# -----------------------------------------------
# Data source que obtiene la VPC default
# -----------------------------------------------
data "aws_vpc" "default" {
  default = true
}

# -----------------------------------------------
# Variables locales
# -----------------------------------------------

locals {
  region = "us-east-1"
  ami = var.ubuntu_ami["us-east-1"]
}

# ---------------------------------------
# Define una instancia EC2 con AMI Ubuntu
# ---------------------------------------
resource "aws_instance" "new_server_1" {
  ami                    = local.ami //Imagen EC2 que se quiere usar
  instance_type          = var.tipo_instancia          //Tipo de instancia
  subnet_id              = data.aws_subnet.az_a.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  user_data              = <<-EOF
                #!/bin/bash
                echo "PRECIOSA!" > index.html
                nohup busybox httpd -f -p ${var.puerto_servidor} &
                EOF
  //Busybox es una aplicación para desplegar un sitio en ubuntu
  tags = {
    "Name"  = "New Server 1" //Con este tag se define el nombre de la instancia en AWS
    "Grupo" = "Test"
  }
}
# ---------------------------------------
# Define la segunda instancia EC2 con AMI Ubuntu
# ---------------------------------------
resource "aws_instance" "new_server_2" {
  ami                    = local.ami //Imagen EC2 que se quiere usar, se obtine de una variable map()
  instance_type          = "t2.micro"                  //Tipo de instancia
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  subnet_id              = data.aws_subnet.az_b.id
  user_data              = <<-EOF
                #!/bin/bash
                echo "TE AMO!" > index.html
                nohup busybox httpd -f -p ${var.puerto_servidor} &
                EOF
  //Busybox es una aplicación para desplegar un sitio en ubuntu
  tags = {
    "Name"  = "New Server 2" //Con este tag se define el nombre de la instancia en AWS
    "Grupo" = "Test"
  }
}
# ------------------------------------------------------
# Define un grupo de seguridad con acceso al puerto 8080
# ------------------------------------------------------
resource "aws_security_group" "my_sg" {
  name = "dev_security_group"
  ingress { //Define una regla de entrada
    security_groups = [aws_security_group.sg_alb.id]
    description     = "Acceso al puerto 8080 desde todos los destinos"
    from_port       = var.puerto_servidor
    to_port         = var.puerto_servidor
    protocol        = "TCP"
  }

}
# ----------------------------------------
# Load Balancer público con dos instancias
# ----------------------------------------
resource "aws_lb" "alb" {
  load_balancer_type = "application"
  name               = "terraform-alb"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [data.aws_subnet.az_a.id, data.aws_subnet.az_b.id]
}

# ------------------------------------
# Security group para el Load Balancer
# ------------------------------------
resource "aws_security_group" "sg_alb" {
  name = "alb_sg"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso al puerto 80 desde todos los destinos"
    from_port   = var.puerto_loadbalancer
    to_port     = var.puerto_loadbalancer
    protocol    = "TCP"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso al puerto 80 desde nuestros servidores"
    from_port   = var.puerto_servidor
    to_port     = var.puerto_servidor
    protocol    = "TCP"
  }

  # ----------------------------------
  # Target Group para el Load Balancer
  # ----------------------------------
}
resource "aws_lb_target_group" "tg_alb" {
  name     = "tg-alb"
  port     = var.puerto_loadbalancer
  vpc_id   = data.aws_vpc.default.id
  protocol = "HTTP"

  health_check {
    enabled  = true
    matcher  = "200"
    path     = "/"
    port     = var.puerto_loadbalancer
    protocol = "HTTP"
  }

}

# -----------------------------
# Attachment para el servidor 1
# -----------------------------
resource "aws_lb_target_group_attachment" "servidor1" {
  target_group_arn = aws_lb_target_group.tg_alb.arn
  target_id        = aws_instance.new_server_1.id
  port             = var.puerto_servidor
}
# -----------------------------
# Attachment para el servidor 2
# -----------------------------
resource "aws_lb_target_group_attachment" "servidor2" {
  target_group_arn = aws_lb_target_group.tg_alb.arn
  target_id        = aws_instance.new_server_2.id
  port             = var.puerto_servidor
}
# ------------------------
# Listener para nuestro LB
# ------------------------
resource "aws_lb_listener" "listener_lb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.puerto_loadbalancer
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg_alb.arn
    type             = "forward"
  }
}

