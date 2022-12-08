output "ca_public_key" {
  value = module.eks_private_cert.ca_public_key
}

output "public_key" {
  value = module.eks_private_cert.public_key
}

output "private_key" {
  value = module.eks_private_cert.private_key
}