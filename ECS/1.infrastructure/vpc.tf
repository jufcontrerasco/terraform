provider "aws" {
  region  = var.aws_region
  profile = "felipedev"
}

terraform {
  backend "s3" {
    bucket  = "ecs-state-terraform"
    key     = "PROD/infrastructure.tfstate"
    region  = "us-east-1"
    profile = "felipedev"
  }
}

resource "aws_vpc" "prd_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name    = "Production-VPC"
    entorno = "PRD"
  }
}

resource "aws_subnet" "public-subnet-1" {
  cidr_block        = var.public_subnet_cidr_1
  vpc_id            = aws_vpc.prd_vpc.id
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "Public-Subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  cidr_block        = var.public_subnet_cidr_2
  vpc_id            = aws_vpc.prd_vpc.id
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "Public-Subnet-2"
  }
}

resource "aws_subnet" "private-subnet-1" {
  cidr_block        = var.private_subnet_cidr_1
  vpc_id            = aws_vpc.prd_vpc.id
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "Private-Subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  cidr_block        = var.private_subnet_cidr_2
  vpc_id            = aws_vpc.prd_vpc.id
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "Private-Subnet-2"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.prd_vpc.id
  tags = {
    Name = "Public-route-table"
  }
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.prd_vpc.id
  tags = {
    Name = "Private-route-table"
  }
}

resource "aws_route_table_association" "public-route-table-1-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-1.id
}

resource "aws_route_table_association" "public-route-table-2-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-2.id
}

resource "aws_route_table_association" "private-route-table-1-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-1.id
}

resource "aws_route_table_association" "private-route-table-2-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-2.id
}

#----------------------------------
# Create elastic Ip for NAT Gateway
# --------------------------------
resource "aws_eip" "elastic-ip-for-nat-gw" {
  vpc                       = true
  associate_with_private_ip = "10.0.0.5"

  tags = {
    Name = "Production-EIP"
  }
}

#----------------------------------
# Create NAT Gateway
# --------------------------------

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.elastic-ip-for-nat-gw.id
  subnet_id     = aws_subnet.public-subnet-1.id
  tags = {
    Name = "Production-NAT-GW"
  }
}

#----------------------------------
# Create route for our private subnet have connection to Internet
# --------------------------------

resource "aws_route" "nat-gw-route" {
  route_table_id         = aws_route_table.private-route-table.id
  nat_gateway_id         = aws_nat_gateway.nat-gw.id
  destination_cidr_block = "0.0.0.0/0"
}

#----------------------------------
# Create Internet Gateway
# --------------------------------
resource "aws_internet_gateway" "production-igw" {
  vpc_id = aws_vpc.prd_vpc.id
  tags = {
    Name = "Production-IGW"
  }
}

#----------------------------------
# Create route for our public subnets have connection to Internet
# --------------------------------

resource "aws_route" "public-internet-gw-route" {
  route_table_id         = aws_route_table.public-route-table.id
  gateway_id             = aws_internet_gateway.production-igw.id
  destination_cidr_block = "0.0.0.0/0"
}