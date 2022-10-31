# Generic Variables
aws_region = "ap-northeast-2"
environment = "dev"
business_divsion = "idt"

# VPC Variables 
vpc_name = "eks-vpc"
vpc_cidr_block = "10.0.0.0/16"
vpc_availability_zones = ["ap-northeast-2a", "ap-northeast-2b"]
vpc_public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
vpc_private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
vpc_database_subnets= ["10.0.151.0/24", "10.0.152.0/24"]
vpc_create_database_subnet_group = true 
vpc_create_database_subnet_route_table = true   
vpc_enable_nat_gateway = true  
vpc_single_nat_gateway = true

#Key
private_key_file_path = "D:/Key/eks-terraform-key.pem"
bastion_instance_keypair = "eks-terraform-key"
