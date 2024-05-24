locals {
  assumed_role_arn = data.aws_caller_identity.current.arn
  account_id       = data.aws_caller_identity.current.account_id
  role_name        = regex("arn:aws:sts::\\d+:assumed-role/(.+?)/", local.assumed_role_arn)[0]
  iam_role_arn     = "arn:aws:iam::${local.account_id}:role/${local.role_name}"
}

data "aws_caller_identity" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.11.1"

  cluster_name                    = var.environment
  cluster_version                 = var.eks_cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_ip_family = "ipv4"

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  iam_role_additional_policies = {
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  enable_cluster_creator_admin_permissions = true

  cluster_tags = local.tags

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    default_node_group = {
      use_custom_launch_template = false

      disk_size = 50

      al2023_nodeadm = {
        ami_type = "AL2023_x86_64_STANDARD"

        use_latest_ami_release_version = true

        cloudinit_pre_nodeadm = [
          {
            content_type = "application/node.eks.aws"
            content      = <<-EOT
            ---
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                config:
                  shutdownGracePeriod: 30s
                  featureGates:
                    DisableKubeletCloudCredentialProviders: true
          EOT
          }
        ]
      }
    }
  }
}
