terraform {
  backend "s3" {
    bucket         = "jiomart-terraform-state-dev-uma"
    key            = "development/terraform.tfstate" # Isolated path
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock-dev"
    encrypt        = true
  }
}
