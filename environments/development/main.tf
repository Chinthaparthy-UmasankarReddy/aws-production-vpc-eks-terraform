module "vpc" {
  source           = "../../modules/vpc"
  env              = "dev"
  vpc_name         = "jiomart-dev-vpc"
  vpc_cidr         = "10.10.0.0/16" # Different CIDR to avoid overlap
  private_subnets  = ["10.10.1.0/24", "10.10.2.0/24"]
  public_subnets   = ["10.10.101.0/24", "10.10.102.0/24"]
  database_subnets = ["10.10.201.0/24", "10.10.202.0/24"]
  is_production    = false # Disables multi-AZ NAT for cost savings
}

module "eks" {
  source          = "../../modules/eks"
  cluster_name    = "jiomart-dev-cluster"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  min_nodes       = 1 # Dev only needs 1-2 nodes
}


module "auth_db" {
  source          = "../../modules/rds"
  db_name         = "jiomart_auth_dev"
  engine          = "postgres"
  engine_version  = "15"
#  auto_minor_version_upgrade = true # Best practice for Dev/Staging
  db_port         = 5432
  username        = "dbadmin"
  password        = var.db_password
  vpc_id          = module.vpc.vpc_id
  db_subnet_group = module.vpc.database_subnet_group_name
  eks_node_sg_id  = module.eks.node_security_group_id
  #  multi_az        = false # Dev doesn't need high availability
}
