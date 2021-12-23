provider "aws" {
    region = local.region
    profile = "devfelipe"  
}

locals {
        region = "us-east-1"        
}

#------------------------------
#Create Data for to define remote state configuration 
#---------------------- 

data "terraform_remote_state" "infrastructure" {
    backend = "s3"
    config = {
      bucket  = "${var.bucket}"
      key     = "${var.key}"
      region  = "${local.region}"
      profile = "${var.profile}"
     }
}

#------------------------------
#Create ECS Cluster
#---------------------- 
resource "aws_ecs_cluster" "prd-cluster-fargate" {
    name = "Production_Cluster"  
}
#------------------------------
#Create ALB
#---------------------- 
resource "aws_alb" "ecs_cluster_alb" {
    name = "${var.ecs_cluster_name}-ALB"
    internal = false
    security_groups = ["${aws_security_group.ecs_alb_security_group.id}"]
    subnets = data.terraform_remote_state.infrastructure.outputs.public_subnets

    tags = {
      "name" = "${var.ecs_cluster_name}-ALB"
    }
  
}

resource "aws_lb_target_group" "ecs_target_group_alb" {
  name     = "${var.ecs_cluster_name}-TG"
  port     = 80
  vpc_id   = data.terraform_remote_state.infrastructure.outputs.vpc_id
  protocol = "HTTP"

  tags = {
      Name = "${var.ecs_cluster_name}-TG"
  }

}

resource "aws_alb_listener" "ecs_alb_https_listener" {
    load_balancer_arn = aws_alb.ecs_cluster_alb.arn
    port = 80
    protocol = "HTTP"
    //ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
    //certificate_arn = aws_acm_certificate.ecs_domain_certificate.arn

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.ecs_target_group_alb.arn
    }    
    depends_on = [aws_lb_target_group.ecs_target_group_alb]
}


resource "aws_iam_role" "ecs_cluster_role" {
    name = "${var.ecs_cluster_name}-IAM-Role"
    assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
    {
    "Effect": "Allow",
    "Principal": {
        "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com", "application-autoscaling.amazonaws.com"]
   },
   "Action": "sts:AssumeRole"
   }
   ] 
 }
EOF
}

resource "aws_iam_role_policy" "ecs_cluster_policy" {
  name = "${var.ecs_cluster_name}-IAM-Policy"
  role = aws_iam_role.ecs_cluster_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "ecr:*",
        "dynamodb:*",
        "cloudwatch:*",
        "s3:*",
        "rds:*",
        "sqs:*",
        "sns:*",
        "logs:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


# Create record in route 53 for to link ALB with domain

/* 
resource "aws_route53_record" "ecs_cert_validation_record" {  
  name = "*.${var.ecs_domain_name}"
  type = "A"
  zone_id = data.aws_route53_zone.ecs_domain.zone_id

  alias{
      evaluate_target_health = false
      name = aws_alb.ecs_cluter_alb.dns_name
      zone_id = aws_alb.ecs_cluter_alb.zone_id
  }
}*/