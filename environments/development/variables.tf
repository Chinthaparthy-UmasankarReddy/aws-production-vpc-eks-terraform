variable "env" { default = "development" }
variable "vpc_cidr" { default = "10.10.0.0/16" }
variable "private_subnets" {}
variable "public_subnets" {}
variable "database_subnets" {}
variable "is_production" {}
variable "db_password" {
  type      = string
  sensitive = true
  default   = "Uma12345"
}
