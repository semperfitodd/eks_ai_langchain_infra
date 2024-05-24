terraform {
  backend "s3" {
    bucket = "casm-learning-terraform-state"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}
