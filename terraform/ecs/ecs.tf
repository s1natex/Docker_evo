resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project}/frontend"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "passgen" {
  name              = "/ecs/${var.project}/passgen"
  retention_in_days = 14

  tags = var.tags
}

data "aws_caller_identity" "acc" {}

locals {
  registry_url_frontend = "${data.aws_caller_identity.acc.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo_frontend}:${var.image_tag}"
  registry_url_passgen  = "${data.aws_caller_identity.acc.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo_pass_gen}:${var.image_tag}"
}

resource "aws_service_discovery_private_dns_namespace" "ns" {
  name        = "svc.local"
  description = "Private DNS namespace for ECS services"
  vpc         = aws_vpc.this.id

  tags = var.tags
}

resource "aws_service_discovery_service" "passgen" {
  name = "pass-gen"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ns.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = var.tags
}

resource "aws_lb" "public" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets = [
    for s in aws_subnet.public : s.id
  ]
  security_groups = [
    aws_security_group.alb.id
  ]

  tags = var.tags
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.project}-tg-frontend"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_ecs_task_definition" "frontend" {
  family       = "${var.project}-frontend"
  cpu          = var.frontend_cpu
  memory       = var.frontend_memory
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task_role.arn

  container_definitions = jsonencode(
    [
      {
        name      = "frontend"
        image     = local.registry_url_frontend
        essential = true
        portMappings = [
          {
            containerPort = 3000
            hostPort      = 3000
            protocol      = "tcp"
          }
        ]
        environment = [
          {
            name  = "BACKEND_URL"
            value = "http://pass-gen.svc.local:5000"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.frontend.name
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "ecs"
          }
        }
        healthCheck = {
          command = [
            "CMD-SHELL",
            "node -e \"fetch('http://localhost:3000/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))\""
          ]
          startPeriod = 10
          interval    = 15
          timeout     = 5
          retries     = 3
        }
      }
    ]
  )

  tags = var.tags
}

resource "aws_ecs_task_definition" "passgen" {
  family       = "${var.project}-pass-gen"
  cpu          = var.passgen_cpu
  memory       = var.passgen_memory
  network_mode = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]
  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task_role.arn

  container_definitions = jsonencode(
    [
      {
        name      = "pass-gen"
        image     = local.registry_url_passgen
        essential = true
        portMappings = [
          {
            containerPort = 5000
            hostPort      = 5000
            protocol      = "tcp"
          }
        ]
        secrets = [
          {
            name      = "DATABASE_URL"
            valueFrom = "${aws_secretsmanager_secret.db_url.arn}:DATABASE_URL::"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.passgen.name
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "ecs"
          }
        }
        healthCheck = {
          command = [
            "CMD-SHELL",
            "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:5000/health').read()\""
          ]
          startPeriod = 10
          interval    = 15
          timeout     = 5
          retries     = 3
        }
      }
    ]
  )

  tags = var.tags
}

resource "aws_ecs_service" "passgen" {
  name            = "${var.project}-pass-gen"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.passgen.arn
  desired_count   = var.desired_count_passgen
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = false
    security_groups = [
      aws_security_group.ecs_tasks.id
    ]
    subnets = [
      for s in aws_subnet.private : s.id
    ]
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_execute_command             = true

  service_registries {
    registry_arn = aws_service_discovery_service.passgen.arn
  }

  tags = var.tags
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.project}-frontend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.desired_count_frontend
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = false
    security_groups = [
      aws_security_group.ecs_tasks.id
    ]
    subnets = [
      for s in aws_subnet.private : s.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 3000
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_execute_command             = true

  tags = var.tags

  depends_on = [
    aws_lb_listener.http
  ]
}
