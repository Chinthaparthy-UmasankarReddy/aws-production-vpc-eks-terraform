# 1. The Core Cluster Control Plane
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.33"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true
  bootstrap_self_managed_addons            = false

  # Core Add-ons get deployed onto the cluster plane immediately
  cluster_addons = {
    coredns = {
      most_recent                 = true
      before_compute              = false # CoreDNS needs nodes to run
      resolve_conflicts_on_create = "OVERWRITE"
    }
    kube-proxy = {
      most_recent                 = true
      before_compute              = true  # Kube-proxy can sit on control plane
      resolve_conflicts_on_create = "OVERWRITE"
    }
    vpc-cni = {
      most_recent                 = true
      before_compute              = true  # CRITICAL: CNI must be ready BEFORE nodes boot
      resolve_conflicts_on_create = "OVERWRITE"
    }
  }
}

# 2. Standalone Managed Node Group Module (Separates Compute from Control Plane)
module "eks_managed_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 20.0"

  name            = "jiomart-nodes"
  cluster_name    = module.eks.cluster_name
  cluster_version = "1.33"

  # Pass the subnets here
  subnet_ids = var.private_subnets

  # 🚀 THE FIX: Forward the internal service CIDR from the control plane module
  cluster_service_cidr = module.eks.cluster_service_cidr

  # Allocate cluster permissions automatically via the core control plane outputs
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]

  instance_types = ["t3.medium"]
  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = var.capacity_type

  min_size     = var.min_nodes
  max_size     = 10
  desired_size = var.min_nodes

  # Tells the node group profile what IAM role execution policies to inherit
  iam_role_additional_policies = {
    AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }
}