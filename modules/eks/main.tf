module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  # Enabling IAM Roles for Service Accounts (IRSA)
  enable_irsa = true
  
  # DD THIS LINE HERE TO MATCH RUNNING INFRASTRUCTURE REALITY
  bootstrap_self_managed_addons = false

  eks_managed_node_groups = {
    jiomart_nodes = {
      instance_types = ["t3.medium"]
      ami_type       = "BOTTLEROCKET_x86_64" # Best for security
      min_size       = var.min_nodes
      max_size       = 10
      desired_size   = var.min_nodes
    }
  }

  # Cluster Access (Restrict to VPC or Admin CIDR in Real Prod)
  cluster_endpoint_public_access = true
}
