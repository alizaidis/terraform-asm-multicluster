#Printing out VPC and Subnet details
output "network_name" {
  value = module.asmvpc.network_name
}

output "subnet_names" {
  value = module.asmvpc.subnets_names
}

output "subnets_regions" {
  value = module.asmvpc.subnets_regions
}

output "cloud_build_worker_pool_name" {
  value = google_cloudbuild_worker_pool.private-build-pool.name
}