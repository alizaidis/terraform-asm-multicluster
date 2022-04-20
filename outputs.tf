#Printing out VPC and Subnet details
output "network_name" {
  value = module.asm-vpc.network_name
}

output "subnet_names" {
  value = module.asm-vpc.subnets_names
}

output "subnets_regions" {
  value = module.asm-vpc.subnets_regions
}