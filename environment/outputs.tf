output "vpc" {
  value = {
    vpc_id           = module.vpc.vpc_id
    vpc_cidr_block   = module.vpc.vpc_cidr_block
    private_subnets  = module.vpc.private_subnets
    public_subnets   = module.vpc.public_subnets
    database_subnets = module.vpc.database_subnets
    nat_public_ips   = module.vpc.nat_public_ips
    azs              = module.vpc.azs
  }
}

output "bastion" {
  value = {
    sequrity_group_id = module.bastion_public_sg.security_group_id
    bastion_host_id   = module.bastion_ec2_instance.id
    bastion_host_eip  = aws_eip.bastion_eip.public_ip
  }
}

