module "site_s3_bucket" {
  for_each = var.agents

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.1.2"

  bucket = "${var.company}-${var.environment}-${each.key}-${random_string.this.result}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  expected_bucket_owner = data.aws_caller_identity.current.account_id

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(local.tags, {
    name = each.key
  })
}

resource "random_string" "this" {
  length = 4

  lower   = true
  numeric = true
  special = false
  upper   = false
}