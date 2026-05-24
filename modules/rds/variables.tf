variable "db_name" {}
variable "engine" {}
variable "engine_version" {}
variable "db_port" {}
variable "username" {}
variable "password" {}
variable "vpc_id" {}
variable "db_subnet_group" {}
variable "eks_node_sg_id" {}
variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false # Default to false for Dev, override to true for Staging/Prod
}
