#Printing out cluster attributes
output "cluster_1_location" {
  value = module.gke_2.location
}

output "cluster_1_name" {
  value = module.gke_1.name
}

output "cluster_2_location" {
  value = module.gke_2.location
}

output "cluster_2_name" {
  value = module.gke_1.name
}

# output "master_authorized_networks" {
#   value = module.gke.master_authorized_networks.cloudshell.cidr_block
# }
