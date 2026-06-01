module "vpc" {
  source           = "../../modules/vpc"
  env              = var.env
  vpc_name         = "jiomart-${var.env}-vpc"
  vpc_cidr         = var.vpc_cidr
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets
  is_production    = true # Enforces Multi-AZ HA NAT Gateways per AZ
}

module "eks" {
  source          = "../../modules/eks"
  cluster_name    = var.cluster_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  min_nodes       = 3            # Enforces baseline High Availability across AZs
  capacity_type   = "ON_DEMAND"  # Guarantees application instance stability
}

module "order_db" {
  source          = "../../modules/rds"
  db_name         = "jiomart_orders_${var.env}"
  engine          = "mysql"
  engine_version  = "8.0"
  db_port         = 3306
  username        = var.db_username # Fixed: Parameterized for secure configuration control
  password        = var.db_password
  vpc_id          = module.vpc.vpc_id
  db_subnet_group = module.vpc.database_subnet_group_name
  eks_node_sg_id  = module.eks.node_security_group_id
  multi_az        = true # Synchronous replication to standby AZ for zero data loss
}