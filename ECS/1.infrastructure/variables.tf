variable "aws_region" {
  default     = "us-east-1"
  description = "Region de AWS"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "VPC CIDR"
}

variable "public_subnet_cidr_1" {
  description = "Public Subnet CIDR 1"
}

variable "public_subnet_cidr_2" {
  description = "Public Subnet CIDR 2"
}

variable "private_subnet_cidr_1" {
  description = "Private Subnet CIDR 1"
}

variable "private_subnet_cidr_2" {
  description = "Private Subnet CIDR 2"
}