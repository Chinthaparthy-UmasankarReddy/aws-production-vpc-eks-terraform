module "vpc" {
  source             = "../../modules/vpc"
  env                = "staging"
  vpc_name           = "jiomart-staging-vpc"
  vpc_cidr           = "10.20.0.0/16" 
  private_subnets    = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
  public_subnets     = ["10.20.101.0/24", "10.20.102.0/24", "10.20.103.0/24"]
  database_subnets   = ["10.20.201.0/24", "10.20.202.0/24"]
  is_production      = true # We want HA NAT Gateways in Staging too
}

module "eks" {
  source          = "../../modules/eks"
  cluster_name    = "jiomart-staging-cluster"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  min_nodes       = 2
  capacity_type   = "SPOT" # Practice tip: Use Spot for Staging to save cost
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
  multi_az        = true # Staging MUST be Multi-AZ to test failover
}
