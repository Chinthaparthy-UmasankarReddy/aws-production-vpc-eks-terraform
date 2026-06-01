variable "env" { default = "staging" }
variable "vpc_cidr" { default = "10.20.0.0/16" }
variable "private_subnets" { type = list(string) }
variable "public_subnets" { type = list(string) }
variable "database_subnets" { type = list(string) }
variable "is_production" { type = bool }

variable "db_password" {
  type      = string
  sensitive = true
  default   = "Uma567890" # For real CI/CD pipelines, inject this via an environment variable or Secret Manager
}