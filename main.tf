terraform {
  backend "s3" {
    bucket         = "demo-private-ecs-terraform-state-1337"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform_state"
  }
  # backend "local" {}
}

data "aws_availability_zones" "available" {}

locals {
  region = "us-east-1"
  name   = "demo-private-ecs"

  vpc_cidr = "10.16.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)

  container_image_uri = "065412124581.dkr.ecr.us-east-1.amazonaws.com/my-express-test-app:3c75d92226274a602e956394f1eaa1afc1435479"
  container_name      = "my-express-test-app"
  container_port      = 3000

  tags = {
    Example = local.name
  }
}
