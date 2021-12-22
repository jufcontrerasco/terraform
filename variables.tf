variable "puerto_servidor" {
  description = "Puerto para las instancias EC2"
  type        = number
  //default     = 8080 //con el tf.vars.json se pueden definir tambien

  /*validation {
    condition     = var.puerto_servidor > 0 && var.puerto_servidor <= 65536
    error_message = "El valor del puerto debe estar comprendido entre 1 y 65536"
  }*/

}
variable "puerto_loadbalancer" {
  description = "Puerto para el ALB"
  type        = number
  //default     = 80 //con el tf.vars.json se pueden definir tambien

  /*validation {
    condition     = var.puerto_loadbalancer > 0 && var.puerto_servidor <= 65536
    error_message = "El valor del puerto debe estar comprendido entre 1 y 65536"
  }*/
}
variable "tipo_instancia" {
  description = "Tipo de instancia para los EC2"
  type        = string
  default     = "t2.micro"
}

variable "ubuntu_ami" {
  description = "AMI de Ubuntu"
  type        = map(string)
  default = {
    "us-east-1" = "ami-0e472ba40eb589f49",
    "us-east-2" = ""
  }

}