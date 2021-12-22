provider "aws" { // Provider para enlazar con la cuenta de AWS
  region  = "us-east-1"
  profile = "felipedev"
}

data "aws_subnet" "az_a" { //DataSource
  availability_zone = "us-east-1a"
}
data "aws_subnet" "az_b" { //DataSource
  availability_zone = "us-east-1b"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_lb" "alb" {
  load_balancer_type = "application"
  name               = "terraform-alb"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [data.aws_subnet.az_a.id, data.aws_subnet.az_b.id]
}

resource "aws_lb_target_group" "tg_alb" {
  name     = "tg-alb"
  port     = 80
  vpc_id   = data.aws_vpc.default.id
  protocol = "HTTP"

  health_check {
    enabled  = true
    matcher  = "200"
    path     = "/"
    port     = "8080"
    protocol = "HTTP"
  }

}

resource "aws_lb_target_group_attachment" "servidor1" {
  target_group_arn = aws_lb_target_group.tg_alb.arn
  target_id        = aws_instance.new_server_1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "servidor2" {
  target_group_arn = aws_lb_target_group.tg_alb.arn
  target_id        = aws_instance.new_server_2.id
  port             = 8080
}

resource "aws_lb_listener" "listener_lb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg_alb.arn
    type             = "forward"
  }
}

resource "aws_security_group" "sg_alb" {
  name = "alb_sg"
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso al puerto 80 desde todos los destinos"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso al puerto 80 desde nuestros servidores"
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
  }
}

resource "aws_instance" "new_server_1" {
  ami                    = "ami-0e472ba40eb589f49" //Imagen EC2 que se quiere usar
  instance_type          = "t2.micro"              //Tipo de instancia
  subnet_id              = data.aws_subnet.az_a.id
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  user_data              = <<-EOF
                #!/bin/bash
                echo "Hola Felipe, soy el servidor 1" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
  //Busybox es una aplicación para desplegar un sitio en ubuntu
  tags = {
    "Name"  = "New Server 1" //Con este tag se define el nombre de la instancia en AWS
    "Grupo" = "Test"
  }
}

resource "aws_instance" "new_server_2" {
  ami                    = "ami-0e472ba40eb589f49" //Imagen EC2 que se quiere usar
  instance_type          = "t2.micro"              //Tipo de instancia
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  subnet_id              = data.aws_subnet.az_b.id
  user_data              = <<-EOF
                #!/bin/bash
                echo "Hola Felipe, soy el servidor 2" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
  //Busybox es una aplicación para desplegar un sitio en ubuntu
  tags = {
    "Name"  = "New Server 2" //Con este tag se define el nombre de la instancia en AWS
    "Grupo" = "Test"
  }
}

resource "aws_security_group" "my_sg" {
  name = "dev_security_group"
  ingress { //Define una regla de entrada
    security_groups = [aws_security_group.sg_alb.id]
    description     = "Acceso al puerto 8080 desde todos los destinos"
    from_port       = 8080
    to_port         = 8080
    protocol        = "TCP"
  }


}