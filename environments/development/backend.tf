terraform {
  backend "s3" {
    bucket         = "jiomart-terraform-state-dev-uma"
    key            = "development/terraform.tfstate" # Isolated path
    region         = "ap-south-1"
    use_lockfile = true # <-- The modern way
    encrypt        = true
  }
}
