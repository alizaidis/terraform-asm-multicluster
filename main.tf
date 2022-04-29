# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#Enabling Services
resource "null_resource" "previous" {}

resource "time_sleep" "wait_120_seconds" {
  depends_on = [null_resource.previous]

  create_duration = "120s"
}

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
    "artifactregistry.googleapis.com",
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
module "asmvpc" {
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
      subnet_private_access = "true"
    }
    ,
    {
      subnet_name   = "${var.subnet_2_name}"
      subnet_ip     = "${var.subnet_2_ip}"
      subnet_region = "${var.region_2}"
      subnet_private_access = "true"
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

# Cloud NAT related resources to provide egress traffic path from regions

resource "google_compute_router" "router_1" {
  name    = "${var.region_1}-router"
  region  = var.region_1
  network = var.vpc
  bgp {
    advertise_mode     = "DEFAULT"
    advertised_groups  = []
    asn                = 64514
    keepalive_interval = 20
    }

  depends_on = [module.asmvpc]
}

resource "google_compute_router" "router_2" {
  name    = "${var.region_2}-router"
  region  = var.region_2
  network = var.vpc
  bgp {
    advertise_mode     = "DEFAULT"
    advertised_groups  = []
    asn                = 64514
    keepalive_interval = 20
    }

  depends_on = [module.asmvpc]
}

resource "google_compute_address" "address_region_1" {
  count  = 1
  name   = "nat-ip-${var.region_1}-${count.index}"
  region = var.region_1
  depends_on = [module.asmvpc]
}

resource "google_compute_address" "address_region_2" {
  count  = 1
  name   = "nat-ip-${var.region_2}-${count.index}"
  region = var.region_2
  depends_on = [module.asmvpc]
}

resource "google_compute_router_nat" "nat_region_1" {
  name   = "${var.region_1}-nat"
  router = google_compute_router.router_1.name
  region = google_compute_router.router_1.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.address_region_1.*.self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = "${var.subnet_1_name}"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  depends_on = [module.asmvpc]
}

resource "google_compute_router_nat" "nat_region_2" {
  name   = "${var.region_2}-nat"
  router = google_compute_router.router_2.name
  region = google_compute_router.router_2.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.address_region_2.*.self_link

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = "${var.subnet_2_name}"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  depends_on = [module.asmvpc]
}

# Resources for Cloud Build private pool
resource "google_compute_global_address" "build_worker_range" {
  name          = "worker-pool-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.asmvpc.network_name
}

resource "google_service_networking_connection" "worker_pool_conn" {
  network                 = module.asmvpc.network_id
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
    peered_network = module.asmvpc.network_id
  }
  depends_on = [google_service_networking_connection.worker_pool_conn]
}

