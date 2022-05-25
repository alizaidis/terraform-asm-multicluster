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

# google_client_config and kubernetes provider must be explicitly specified like the following for every cluster.


## ASM 1

data "google_client_config" "gke_1_config" {}

data "google_container_cluster" "gke_1" {
  name     = var.gke_1_name
  location = var.region_1
}

provider "kubernetes" {
  alias                  = "gke_1"
  host                   = "https://${data.google_container_cluster.gke_1.endpoint}"
  token                  = data.google_client_config.gke_1_config.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.gke_1.master_auth.0.cluster_ca_certificate)
  proxy_url              = "http://10.128.12.8:3128"
}

module "workload_identity_1" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "20.0.0"
  gcp_sa_name         = "cnrmsa1"
  cluster_name        = data.google_container_cluster.gke_1.name
  name                = "cnrm-controller-manager"
  location            = var.region_1
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
  namespace           = "cnrm-system"
  project_id          = var.project_id
  roles               = ["roles/owner"]
}

module "asm_1" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/asm"
  version = "20.0.0"
  cluster_name     = var.gke_1_name
  cluster_location = var.region_1
  project_id = var.project_id
  enable_cni = var.enable_cni
  providers = {
    kubernetes = kubernetes.gke_1
  }
}

## ASM 2

data "google_client_config" "gke_2_config" {}

data "google_container_cluster" "gke_2" {
  name     = var.gke_2_name
  location = var.region_2
}

provider "kubernetes" {
  alias                  = "gke_2"
  host                   = "https://${data.google_container_cluster.gke_2.endpoint}"
  token                  = data.google_client_config.gke_2_config.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.gke_2.master_auth.0.cluster_ca_certificate)
  proxy_url              = "http://10.128.12.8:3128"
}

module "workload_identity_2" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "20.0.0"
  gcp_sa_name         = "cnrmsa2"
  cluster_name        = data.google_container_cluster.gke_2.name
  name                = "cnrm-controller-manager"
  location            = var.region_2
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
  namespace           = "cnrm-system"
  project_id          = var.project_id
  roles               = ["roles/owner"]
}

module "asm_2" { 
  source = "terraform-google-modules/kubernetes-engine/google//modules/asm"
  version = "20.0.0"
  cluster_name     = var.gke_2_name
  cluster_location = var.region_2
  project_id = var.project_id
  enable_cni = var.enable_cni
  providers = {
    kubernetes = kubernetes.gke_2
  }
}