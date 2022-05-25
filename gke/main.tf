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

data "google_compute_global_address" "build_worker_range" {
  name = "worker-pool-range"
}

# google_client_config and kubernetes provider must be explicitly specified like the following for every cluster.

## GKE 1

data "google_client_config" "gke_1_config" {}

provider "kubernetes" {
  alias                  = "gke_1"
  host                   = "https://${module.gke_1.endpoint}"
  token                  = data.google_client_config.gke_1_config.access_token
  cluster_ca_certificate = base64decode(module.gke_1.ca_certificate)
}

module "gke_1" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version                    = "20.0.0"
  project_id                 = var.project_id
  name                       = var.gke_1_name
  release_channel            = var.gke_channel
  region                     = var.region_1
  zones                      = [var.zone_1]
  initial_node_count         = 4
  service_account            = "create"
  network                    = var.vpc
  subnetwork                 = var.subnet_1_name
  ip_range_pods              = "${var.subnet_1_name}-pod-cidr"
  ip_range_services          = "${var.subnet_1_name}-svc-cidr"
  config_connector           = true
  enable_private_endpoint    = true
  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "vpc"
    },
    {
      cidr_block   = "${data.google_compute_global_address.build_worker_range.address}/24"
      display_name = "cloudbuild"
    }
  ]
  enable_private_nodes       = true
  master_ipv4_cidr_block     = "10.200.1.0/28"
}


resource "google_gke_hub_membership" "membership_1" {
  provider      = google-beta
  
  membership_id = "membership-hub-${module.gke_1.name}"
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${module.gke_1.cluster_id}"
    }
  }
  depends_on = [module.gke_1.name] 
}


## GKE 2

data "google_client_config" "gke_2_config" {}

provider "kubernetes" {
  alias                  = "gke_2"
  host                   = "https://${module.gke_2.endpoint}"
  token                  = data.google_client_config.gke_2_config.access_token
  cluster_ca_certificate = base64decode(module.gke_2.ca_certificate)
}

module "gke_2" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version                    = "20.0.0"
  project_id                 = var.project_id
  name                       = var.gke_2_name
  release_channel            = var.gke_channel
  region                     = var.region_2
  zones                      = [var.zone_2]
  initial_node_count         = 4
  service_account            = "create"
  network                    = var.vpc
  subnetwork                 = var.subnet_2_name
  ip_range_pods              = "${var.subnet_2_name}-pod-cidr"
  ip_range_services          = "${var.subnet_2_name}-svc-cidr"
  config_connector           = true
  enable_private_endpoint    = true
  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "vpc"
    },
    {
      cidr_block   = "${data.google_compute_global_address.build_worker_range.address}/24"
      display_name = "cloudbuild"
    }
  ]
  enable_private_nodes       = true
  master_ipv4_cidr_block     = "10.200.2.0/28"
}

resource "google_gke_hub_membership" "membership_2" {
  provider      = google-beta
  
  membership_id = "membership-hub-${module.gke_2.name}"
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${module.gke_2.cluster_id}"
    }
  }
  depends_on = [module.gke_2.name] 
}

resource "google_compute_firewall" "cloud_build_ingress" {
  name    = "cloug-build-ingress"
  network = var.vpc

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  priority = 0
  source_ranges = ["${data.google_compute_global_address.build_worker_range.address}/24"]
}