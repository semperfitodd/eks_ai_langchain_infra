module "dev" {
  source = "./modules/app"

  agents = {
    agent0 = {
      description = "example 0 description"
    }
    agent1 = {
      description = "example 1 description"
    }
    agent2 = {
      description = "example 2 description"
    }
    agent3 = {
      description = "example 3 description"
    }
    agent4 = {
      description = "example 4 description"
    }
  }

  argocd_chart_version = "6.11.1"
  company              = lower(var.company)
  domain               = var.domain
  eks_cluster_version  = "1.29"
  environment          = "dev"
  openvpn_sg           = aws_security_group.openvpn.id
  rds_backup_retention = "3"
  rds_engine_version   = "15.4"
  vpc_cidr             = "10.101.0.0/16"
  vpc_redundancy       = false
}