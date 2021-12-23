provider "aws" {
  region = var.region
}

terraform {
  backend = "s3"

}

data "terraform_remote_state" "platform" {
  backend = "s3"
  config = {
    bucket  = "${var.bucket}"
    key     = "${var.key}"
    region  = "${local.region}"
    profile = "${var.profile}"
  }
}

data "template_file" "ecs_task_definition_template" {
  template = file("task_definition.json")
  vars = {
    "task_definition_name"  = "${var.ecs_service_name}"
    "ecs_service_name"      = "${var.ecs_service_name}"
    "docker_container_port" = "${var.docker_container_port}"
    "docker_image_url"      = "${var.docker_image_url}"
    "memory"                = "${var.memory}"
    "region"                = "${var.region}"
  }
}

resource "aws_ecs_task_definition" "api_task_definition" {
  container_definitions    = data.template_file.ecs_task_definition_template.rendered
  family                   = var.ecs_service_name
  cpu                      = 512
  memory                   = var.memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.fargate_iam_role.arn
  task_role_arn            = aws_iam_role.fargate_iam_role.arn
}

resource "aws_iam_role" "fargate_iam_role" {
  name                     = "${var.ecs_service_name}-IAM-Role"
  assumeassume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
    {
    "Effect": "Allow",
    "Principal": {
        "Service": ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
   },
   "Action": "sts:AssumeRole"
   }
   ] 
} 
EOF
}

resource "aws_iam_role_policy" "fargate_iam_policy" {
  name   = "${var.ecs_service_name}-IAM-Policy"
  role   = aws_iam_role.fargate_iam_role.id
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

resource "aws_security_group" "api_security_group" {
  name        = "${var.ecs_service_name}-SG"
  description = "Security group for API ECS Service"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = data.terraform_remote_state.platform.outputs.vpc_id.vpc_cidr_block
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0 //El puerto 0 y el protocolo -1 define que todo el trafico es permitido
    protocol    = "-1"
    to_port     = 0
  }

  tags = {
    Name = "${var.ecs_service_name}-SG"
  }

}

resource "aws_lb_target_group" "ecs_api_target_group" {
  name     = "${var.ecs_service_name}-TG"
  port     = var.docker_container_port
  vpc_id   = data.terraform_remote_state.platform.outputs.vpc_id
  protocol = "HTTP"

  health_check {
    enabled             = true
    matcher             = "200"
    path                = "/"
    port                = var.docker_container_port
    protocol            = "HTTP"
    interval            = 60
    timeout             = 30
    unhealthy_threshold = "3"
    healthy_threshold   = "3"
  }

  tags = {
    Name = "${var.ecs_service_name}-TG"
  }

}

resource "aws_ecs_service" "ecs_service_api" {
    name = var.ecs_service_name
    task_definition = var.ecs_service_name
    desired_count = var.desired_task_number
    cluster = data.terraform_remote_state.platform.outputs.ecs_cluster_name
    launch_type = "FARGATE"

    network_configuration {
      subnets = data.terraform_remote_state.platform.outputs.ecs_public_subnets
      security_groups = aws_security_group.api_security_group
    }

    load_balancer {
      container_name = var.ecs_service_name
      container_port = var.docker_container_port
      target_group_arn = aws_lb_target_group.ecs_api_target_group.arn
    }
}

resource "aws_lb_listener_rule" "ecs_alb_listener_rule" {
  listener_arn = data.terraform_remote_state.platform.outputs.ecs_alb_listener_arn
  action {
    target_group_arn = aws_lb_target_group.ecs_api_target_group.arn
    type             = "forward"
  }

  /*condition {
    field = "host-header"
    values = ["${lower(var.ecs_service_name)}.${data.terraform_remote_state.platform.outputs.ecs_domain_name}"]
  }*/
}
resource "aws_cloudwatch_log_group" "ecs_api_log_group" {
    name = "${var.ecs_service_name}-LogGroup"
  
}