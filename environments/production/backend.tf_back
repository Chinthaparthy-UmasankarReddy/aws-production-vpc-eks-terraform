terraform {
  backend "s3" {
    bucket         = "jiomart-terraform-state-production-uma"
    key            = "Production/terraform.tfstate" # Isolated path
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock-prod"
    encrypt        = true
  }
}
