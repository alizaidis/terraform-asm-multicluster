#Enabling Services
resource "null_resource" "previous" {}

resource "null_resource" "enable_mesh" {

  provisioner "local-exec" {
    when    = create
    command = "echo y | gcloud container hub mesh enable --project ${var.project_id}"
  }

  depends_on = [module.enabled_google_apis]
}

module "enabled_google_apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "12.0.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false

  activate_apis = [
    "cloudbuild.googleapis.com",
    "containerregistry.googleapis.com",
    "iap.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudapis.googleapis.com",
    "compute.googleapis.com",
    "anthos.googleapis.com",
    "mesh.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
  depends_on = [null_resource.previous]
}

#Creating a VPC for the private GKE clusters and bastion VM
module "asm-vpc" {
  source  = "terraform-google-modules/network/google"
  version = "5.0"

  project_id   = var.project_id
  network_name = var.vpc
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "${var.subnet_1_name}"
      subnet_ip     = "${var.subnet_1_ip}"
      subnet_region = "${var.region_1}"
    }
    ,
    {
      subnet_name   = "${var.subnet_2_name}"
      subnet_ip     = "${var.subnet_2_ip}"
      subnet_region = "${var.region_2}"
    }
  ]

  secondary_ranges = {
    "${var.subnet_1_name}" = [
      {
        range_name    = "${var.subnet_1_name}-pod-cidr"
        ip_cidr_range = "${var.pod_1_cidr}"
      },
      {
        range_name    = "${var.subnet_1_name}-svc-cidr"
        ip_cidr_range = "${var.svc_1_cidr}"
      }
    ]
    "${var.subnet_2_name}" = [
      {
        range_name    = "${var.subnet_2_name}-pod-cidr"
        ip_cidr_range = "${var.pod_2_cidr}"
      },
      {
        range_name    = "${var.subnet_2_name}-svc-cidr"
        ip_cidr_range = "${var.svc_2_cidr}"
      }
    ]
  }

  firewall_rules = [{
    name        = "allow-all-10"
    description = "Allow Pod to Pod connectivity"
    direction   = "INGRESS"
    ranges      = ["10.0.0.0/8"]
    allow = [{
      protocol = "tcp"
      ports    = ["0-65535"]
    }]
  }]
  depends_on = [module.enabled_google_apis]
}

# # GCE VM where the next steps in the guide will run from
# module "iap_bastion" {
#   source = "terraform-google-modules/bastion-host/google"

#   project = var.project_id
#   zone    = var.zone_1
#   network = module.asm-vpc.network_name
#   subnet  = "projects/${var.project_id}/regions/${var.region_1}/subnetworks/${var.subnet_1_name}"
#   members = [
#     "user:zaidiali@google.com",
#   ]
#   depends_on = [module.asm-vpc]
# }

# Firewall rule allowing
resource "google_compute_global_address" "build_worker_range" {
  name          = "worker-pool-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.asm-vpc.network_name
}

resource "google_service_networking_connection" "worker_pool_conn" {
  network                 = module.asm-vpc.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.build_worker_range.name]
  depends_on              = [module.enabled_google_apis]
}

resource "google_cloudbuild_worker_pool" "private-build-pool" {
  name = "private-build-pool"
  location = "${var.region_1}"
  worker_config {
    disk_size_gb = 100
    machine_type = "e2-standard-4"
    no_external_ip = true
  }
  network_config {
    peered_network = module.asm-vpc.network_id
  }
  depends_on = [google_service_networking_connection.worker_pool_conn]
}

