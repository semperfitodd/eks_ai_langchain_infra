locals {
  tags = merge(var.tags, {
    environment = var.environment
  })
}

variable "agents" {
  description = "Map containing information for each agent"
  type        = map(any)
}

variable "argocd_chart_version" {
  description = "ArgoCD helm chart version"
  type        = string
}

variable "company" {
  description = "Company name"
  type        = string
}

variable "domain" {
  description = "Domain"
  type        = string
}

variable "eks_cluster_version" {
  description = "Version of kubernetes running on cluster"
  type        = string
}

variable "environment" {
  description = "Environment all resources will be built"
  type        = string
}

variable "openvpn_sg" {
  description = "OpenVPN Security Group ID"
  type        = string
}

variable "rds_backup_retention" {
  description = "Length of time in days to keep RDS backups"
  type        = string
}

variable "rds_engine_version" {
  description = "Version of postgresql for aurora"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_redundancy" {
  description = "Redundancy for NAT gateways"
  type        = bool
  default     = true
}
