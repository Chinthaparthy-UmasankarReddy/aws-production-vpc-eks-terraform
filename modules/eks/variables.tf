variable "cluster_name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }
variable "min_nodes" { default = 1 } # replace with 3 if need
variable "capacity_type" {
  description = "Type of capacity for the managed node group. Options: ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND" # Default to On-Demand for safety
}
