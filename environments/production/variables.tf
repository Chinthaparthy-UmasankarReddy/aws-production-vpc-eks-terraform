variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "env" {
  type    = string
  default = "prod" # Consolidated to uniform short-string naming
}

variable "cluster_name" {
  type    = string
  default = "jiomart-prod-cluster"
}

# --- VPC Infrastructure Network Variables ---
variable "vpc_cidr" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "database_subnets" {
  type = list(string)
}

# --- Sensitive Credential Variables ---
variable "db_username" {
  type    = string
  default = "jiomart_admin"
}

variable "db_password" {
  description = "RDS Production Root Password"
  type        = string
  sensitive   = true
}