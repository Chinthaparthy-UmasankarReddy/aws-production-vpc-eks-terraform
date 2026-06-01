module "vpc" {
  source           = "../../modules/vpc"
  env              = var.env
  vpc_name         = "jiomart-staging-vpc"
  vpc_cidr         = var.vpc_cidr
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets
  is_production    = var.is_production # <-- Fixed: Respects tfvars variable input configuration
}

module "eks" {
  source          = "../../modules/eks"
  cluster_name    = "jiomart-staging-cluster"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  min_nodes       = 2         # Best practice for staging HA failover testing
  capacity_type   = "ON_DEMAND" # <-- Fixed: Explicitly passes string variable type
}

module "order_db" {
  source          = "../../modules/rds"
  db_name         = "jiomart_orders_staging"
  engine          = "mysql"
  engine_version  = "8.0"
  db_port         = 3306
  username        = "dbadmin"
  password        = var.db_password
  vpc_id          = module.vpc.vpc_id
  db_subnet_group = module.vpc.database_subnet_group_name
  eks_node_sg_id  = module.eks.node_security_group_id
  multi_az        = true # <-- Optimized: Staging database validates true multi-AZ cluster failover
}
