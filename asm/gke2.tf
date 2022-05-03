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

# Manifest to create GKE cluster and install ASM

# google_client_config and kubernetes provider must be explicitly specified like the following for every cluster.

data "google_client_config" "default" {}

## GKE 2

provider "kubernetes" {
  alias                  = "gke_2"
  host                   = "https://${module.gke_2.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke_2.ca_certificate)
}

module "gke_2" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version                    = "~> 16.0"
  project_id                 = var.project_id
  name                       = "asm-cluster-2"
  release_channel            = "${var.gke_channel}"
  region                     = var.region_2
  zones                      = [var.zone_2]
  initial_node_count         = 4
  network                    = var.vpc
  subnetwork                 = var.subnet_2_name
  ip_range_pods              = "${var.subnet_2_name}-pod-cidr"
  ip_range_services          = "${var.subnet_2_name}-svc-cidr"
  config_connector           = true
  enable_private_endpoint    = false
  enable_private_nodes       = true
  master_ipv4_cidr_block     = "172.17.0.0/28"
}

module "workload_identity_2" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 16.0.1"
  gcp_sa_name         = "cnrmsa"
  cluster_name        = module.gke_2.name
  name                = "cnrm-controller-manager"
  location            = var.zone_2
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
  namespace           = "cnrm-system"
  project_id          = var.project_id
  roles               = ["roles/owner"]
}

#Module to create Fleet memebership and install ASM on GKE cluster
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

module "asm_2" { 
  source = "terraform-google-modules/kubernetes-engine/google//modules/asm"
  version = "20.0.0"
  cluster_name     = module.gke_2.name
  cluster_location = var.region_2
  project_id = var.project_id
  enable_cni = var.enable_cni

}