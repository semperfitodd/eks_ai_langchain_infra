terraform {
  backend "s3" {
    bucket = <BUCKET_NAME>
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}
