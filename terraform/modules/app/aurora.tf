locals {
  auto_pause   = var.environment != "prod"
  max_capacity = var.environment == "prod" ? 64 : 16

  instances = var.environment == "prod" ? {
    one = {}
    two = {}
    } : {
    one = {}
  }
}

module "postgresql" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 9.3.1"

  apply_immediately               = true
  backup_retention_period         = var.rds_backup_retention
  copy_tags_to_snapshot           = true
  create_monitoring_role          = true
  database_name                   = var.environment
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name
  db_subnet_group_name            = module.vpc.database_subnet_group
  deletion_protection             = true
  enable_http_endpoint            = true
  engine                          = "aurora-postgresql"
  engine_mode                     = "provisioned"
  engine_version                  = var.rds_engine_version
  master_username                 = "postgres"
  name                            = var.environment
  storage_encrypted               = true
  subnets                         = module.vpc.database_subnets
  tags                            = local.tags
  vpc_id                          = module.vpc.vpc_id

  security_group_rules = {
    eks_ingress = {
      source_security_group_id = module.eks.node_security_group_id
    }

    openvpn_ingress = {
      source_security_group_id = var.openvpn_sg
    }

    egress = {
      cidr_blocks = ["0.0.0.0/0"]
      description = "Egress to everything"
    }
  }

  serverlessv2_scaling_configuration = {
    auto_pause               = local.auto_pause
    max_capacity             = local.max_capacity
    min_capacity             = 2
    seconds_until_auto_pause = 3600
    timeout_action           = "ForceApplyCapacityChange"
  }

  instance_class = "db.serverless"
  instances      = local.instances
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.environment}-aurora-serverless-credentials"
  description             = "${var.environment} aurora username and password"
  recovery_window_in_days = "7"

  depends_on = [module.postgresql]
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode(
    {
      username = module.postgresql.cluster_master_username
      password = module.postgresql.cluster_master_password
    }
  )

  depends_on = [module.postgresql]
}

resource "aws_rds_cluster_parameter_group" "this" {
  name        = var.environment
  family      = "aurora-postgresql15"
  description = "RDS default cluster parameter group"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}