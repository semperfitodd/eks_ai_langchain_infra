output "public_subnets" {
  value = module.vpc.public_subnets
}

output "ssh_keypair" {
  value = aws_key_pair.generated.key_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}