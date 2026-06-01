terraform {
  backend "s3" {
    bucket         = "jiomart-terraform-state-stage-uma"
    key            = "staging/terraform.tfstate" # Isolated path
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock-stage"
    encrypt        = true
  }
}
