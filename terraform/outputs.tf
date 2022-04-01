#Printing out cluster attributes
output "cluster_location" {
  value = module.gke.location
}

output "cluster_name" {
  value = module.gke.name
}

# output "master_authorized_networks" {
#   value = module.gke.master_authorized_networks.cloudshell.cidr_block
# }
