module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  database_subnets = var.database_subnets

  # Production Requirement: NAT Gateway for Private Subnets
  enable_nat_gateway     = true
  single_nat_gateway     = var.is_production ? false : true # True for Dev, False for Prod (High Availability)
  one_nat_gateway_per_az = var.is_production ? true : false

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags for EKS Load Balancer Auto-discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Environment = var.env
    Project     = "JioMart"
  }
}
