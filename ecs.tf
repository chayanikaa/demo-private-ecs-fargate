################################################################################
# Cluster
################################################################################

module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  cluster_name                          = local.name
  default_capacity_provider_use_fargate = true

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 1
        base   = 1
      }
    }
  }

  tags = local.tags
}

################################################################################
# Service
################################################################################

module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = local.name
  cluster_arn = module.ecs_cluster.arn

  cpu                      = 512
  memory                   = 1024
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 1

  task_exec_iam_statements = [
    {
      actions = [
        "logs:CreateLogGroup",
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer"
      ]
      resources = ["*"]
      effect    = "Allow"
    }
  ]

  # Container definition(s)
  container_definitions = {
    # https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html
    my-express-test-app = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = local.container_image_uri
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]
      memory_reservation = 512
    }
  }

  load_balancer = {
    service = {
      target_group_arn = element(module.alb.target_group_arns, 0)
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = module.vpc.private_subnets
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.alb_sg.security_group_id
    }
    # This could be refined further 
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = local.tags
}




