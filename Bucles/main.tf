provider "aws" { // Provider para enlazar con la cuenta de AWS
  region  = "us-east-1"
  profile = "devfelipe"
}

variable "usuarios" {
  type        = set(string)  // Se debe usar set o map, ya que forEach solo recibe estos tipos. Para count se utiliza list(), 
  description = "Lista de Usuarios"
}

variable "usuarios_splat" {
  type        = list(string)  // Para count se utiliza list(), 
  description = "Lista de Usuarios"
}

# -----------------------------------------------
# Recurso para crear usuarios IAM 
# -----------------------------------------------

resource "aws_iam_user" "ejemplo" {
  // count = length(var.usuarios) //Count es una forma de hacer bucle
  for_each = var.usuarios //Se obtiene todo los valores
  name = "usuario-${each.value}" //Hace un bucle con cada uno de los valores del set. Con count se define asi: var.usuarios[count.index]

}

output "usuarios_name_arn" {
  value = {for usuario in aws_iam_user.ejemplo : usuario.name => usuario.arn} // Imprime un mapa donde la key es el nombre del usuario y el valor el arn
  description = "ARN de los usuarios IAM"
}

output "usuarios_arn" {
  value = [for usuario in aws_iam_user.ejemplo :usuario.arn ]
  description = "ARN de los usuarios IAM"
}

# -----------------------
# Splat
#-----------------------
resource "aws_iam_user" "ejemplo_splat" {
  count = length(var.usuarios_splat) //Se obtiene el numero de valores de la lista
  name = "usuario-${count.index}"

}

output "usuarios_arn_splat" {
  value = aws_iam_user.ejemplo_splat[*].arn
  description = "ARN de los usuarios IAM"
}