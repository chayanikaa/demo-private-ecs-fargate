module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name} vpc"
  cidr = local.vpc_cidr

  azs                   = local.azs
  private_subnets       = ["10.16.32.0/20", "10.16.48.0/20"]
  public_subnets        = ["10.16.64.0/20", "10.16.80.0/20"]
  private_subnet_names  = ["ECS example private subnet 1", "ECS example private subnet 2"]
  public_subnet_names   = ["ECS example public subnet 1", "ECS example public subnet 2"]

  enable_nat_gateway                 = true
  single_nat_gateway                 = true
  map_public_ip_on_launch            = true

  tags = local.tags
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name_prefix = "${local.name}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  endpoints = {
    s3 = {
      service             = "s3"
      private_dns_enabled = true
      service_type        = "Gateway"
      tags                = { Name = "S3 Gateway Endpoint" }
      policy              = data.aws_iam_policy_document.s3_endpoint_policy.json
      route_table_ids     = module.vpc.private_route_table_ids
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      tags                = { Name = "ECR API Interface Endpoint" }
      subnet_ids          = [module.vpc.private_subnets[0]] # Interface endpoints are priced per AZ
      policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      tags                = { Name = "ECR DKR Interface Endpoint" }
      subnet_ids          = [module.vpc.private_subnets[0]] # Interface endpoints are priced per AZ
      policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
    },
  }

  tags = merge(local.tags, {
    Project  = "Demo Private ECS with Fargate"
    Endpoint = "true"
  })
}


################################################################################
# Supporting Resources
################################################################################

data "aws_iam_policy_document" "generic_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpc"

      values = [module.vpc.vpc_id]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

data "aws_iam_policy_document" "s3_endpoint_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::prod-${local.region}-starport-layer-bucket/*"] # to access the layer files

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}