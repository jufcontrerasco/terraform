 provider "aws"{ // Provider para enlazar con la cuenta de AWS
     region = "us-east-1"
     profile = "devfelipe"
 }

 resource "aws_instance" "mi_servidor"{
     ami = "ami-04505e74c0741db8d" //Imagen EC2 que se quiere usar
     instance_type = "t2.micro" //Tipo de instancia
     vpc_security_group_ids = [aws_security_group.my_sg.id]
     user_data = <<-EOF
                #!/bin/bash
                echo "Hola Felipe, aprendiendo Terraform?" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
                //Busybox es una aplicación para desplegar un sitio en ubuntu
     tags = {
       "Name" = "Servidor Test" //Con este tag se define el nombre de la instancia en AWS
       "Grupo" = "Test"
     }
 }

 resource "aws_security_group" "my_sg" {
     name = "dev_security_group"
     ingress { //Define una regla de entrada
         cidr_blocks = [ "0.0.0.0/0" ]
         description = "Acceso al puerto 8080 desde todos los destinos"
         from_port = 8080
         to_port = 8080
         protocol = "TCP"
     }

   
 }