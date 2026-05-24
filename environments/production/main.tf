module "vpc" {
  source             = "../../modules/vpc"
  env                = "prod"
  vpc_name           = "jiomart-prod-vpc"
  vpc_cidr           = "10.0.0.0/16"
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets   = ["10.0.201.0/24", "10.0.202.0/24"]
  is_production      = true
}

module "eks" {
  source          = "../../modules/eks"
  cluster_name    = "jiomart-prod-cluster"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  min_nodes       = 3 # Production needs minimum 3 for high availability
  capacity_type   = "ON_DEMAND" # Production MUST use On-Demand for stability
}

module "order_db" {
  source          = "../../modules/rds"
  db_name         = "jiomart_orders_prod"
  engine          = "mysql"
  engine_version  = "8.0"
  db_port         = 3306
  username        = "jiomart_admin"
  password        = var.db_password
  vpc_id          = module.vpc.vpc_id
  db_subnet_group = module.vpc.database_subnet_group_name
  eks_node_sg_id  = module.eks.node_security_group_id
  multi_az        = true
}
