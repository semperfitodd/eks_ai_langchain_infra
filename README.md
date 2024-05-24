# CASM Learning Infrastructure

## Table of Contents
- [Resources](#resources)
- [Usage](#usage)
  - [Prerequisites](#prerequisites)
  - [Variables](#variables)
  - [Main Configuration](#main-configuration)
  - [Running Terraform](#running-terraform)
- [Accessing OpenVPN](#accessing-openvpn)
- [ArgoCD](#argocd)
- [Connecting to EKS Cluster](#connecting-to-eks-cluster)
- [Connect to ECR](#connect-to-ecr)
- [Redundancy Setup](#redundancy-setup)
- [Agent Setup](#agent-setup)


This repository contains Terraform configurations to set up infrastructure for CASM Learning.

## Resources
### Per environment
* Aurora postgresql serverless cluster
* ECR
* EKS
* S3 buckets
* VPC

### Account level
* OpenVPN server

## Usage

### Prerequisites

- Ensure you have Terraform installed. If not, download and install it from the [official site](https://www.terraform.io/downloads.html).
- Ensure you have AWS CLI installed and configured with the necessary permissions (BlueSentry cross-account role.)
- Ensure you have OpenVPN installed for accessing the VPN.

### Variables

**Variables in`terraform.tfvars` file:**
```hcl
company = "casm"
domain = "casmlearning.io"
openvpn_instance_type = "t3.micro"
region = "<AWS_REGION>"
```

The rest are defined in the main configuration.

## Main Configuration
The main configuration is defined in `main.tf`. Here's an example snippet:

```hcl
module "dev" {
  source = "./modules/app"

  eks_cluster_version  = "1.29"
  environment          = "dev"
  openvpn_sg           = aws_security_group.openvpn.id
  rds_backup_retention = "3"
  rds_engine_version   = "15.4"
  vpc_cidr             = "10.101.0.0/16"
  vpc_redundancy       = false
}
```

## Running Terraform
1. Initialize the Terraform configuration:

    ```bash
    terraform init
    ```
2. Validate the configuration:

    ```bash
    terraform validate
    ```
3. Plan the infrastructure changes:

    ```bash
    terraform plan -out=plan.out
    ```
4. Apply the planned changes:
    ```bash
    terraform apply plan.out
    ```

## Accessing OpenVPN

* VPN is accessible at: https://vpn.casmlearning.io

* VPN admin is accessible at: https://vpn.casmlearning.io/admin

## ArgoCD

* Argocd is accessible at: https://argocd-dev.casmlearning.io

## Connecting to EKS Cluster
To access your Kubernetes cluster locally, follow these steps:

1. Connect to the VPN.

2. Update your kubeconfig to use the EKS cluster:

    ```bash
    aws eks update-kubeconfig --region <AWS_REGION> --name dev --profile casm
    
    Added new context arn:aws:eks:<AWS_REGION>:<ACCOUNT_NUMBER>:cluster/dev0
    ```
3. You can now run kubectl commands. For example, to get the list of nodes:
    ```bash
    k get no
                                  
    NAME                           STATUS   ROLES    AGE   VERSION
    ip-10-101-17-85.ec2.internal   Ready    <none>   14m   v1.29.3-eks-ae9a62a
    ```

## Connect to ECR
1. Login to ECR from your terminal

   ```bash
   aws ecr get-login-password --region <AWS_REGION> --profile casm| docker login --username AWS --password-stdin <ACCOUNT_NUMBER>.dkr.ecr.<AWS_REGION>.amazonaws.com
   
   Login Succeeded
   ```
   
2. Tag your image

   ```bash
   docker tag <LOCAL_IMAGE_NAME>:<TAG> <ACCOUNT_NUMBER>.dkr.ecr.<AWS_REGION>.amazonaws.com/<YOUR_IMAGE_NAME>:<TAG>
   ```
   
3. Push your image

   ```bash
   docker push <ACCOUNT_NUMBER>.dkr.ecr.<AWS_REGION>.amazonaws.com/<YOUR_IMAGE_NAME>:<TAG>
   
   The push refers to repository [<ACCOUNT_NUMBER>.dkr.ecr.<AWS_REGION>.amazonaws.com/agent0]
   44fe7d6fb5a2: Pushed
   4c973d2b3e26: Pushed
   94dbb95c1e7e: Pushed
   c72a581e308c: Pushed
   a05626a9d0b0: Pushed
   bb83dfa26f0a: Pushed
   eb8303837857: Pushed
   6e5a1bc9659a: Pushed
   0: digest: sha256:f9ca7279ec961344e18e72de32e6c5fb85fe047ac42fcb49d8dc0da59b9457c4 size: 1985
   ```

## Redundancy Setup
There is redundancy built in for the production environment (var.environment == "prod") and less redundancy for the development environment (var.environment == "dev"). 

For example in `aurora.tf`:
```hcl
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
```

## Agent Setup
Agent resources (S3 bucket and ECR repo) are created dynamically off the `var.agents` variable.

```hcl
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
```

This is called in the modules.
```hcl
#S3 use
bucket = "${var.company}-${var.environment}-${each.key}-${random_string.this.result}"

#ECR use
repository_name = each.key
```
