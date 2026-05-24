variable "aws_region" {
  default = "ap-south-1"
}

variable "env" {
  default = "production"
}

variable "db_password" {
  description = "RDS Root Password"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  default = "jiomart-prod-eks"
}
