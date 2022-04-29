# Manifest to create GKE cluster and install ASM

# google_client_config and kubernetes provider must be explicitly specified like the following for every cluster.

data "google_client_config" "default" {}

## GKE 1

provider "kubernetes" {
  alias                  = "gke_1"
  host                   = "https://${module.gke_1.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke_1.ca_certificate)
}

module "gke_1" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version                    = "~> 16.0"
  project_id                 = var.project_id
  name                       = "asm-cluster-1"
  release_channel            = "${var.gke_channel}"
  region                     = var.region_1
  zones                      = [var.zone_1]
  initial_node_count         = 4
  network                    = var.vpc
  subnetwork                 = var.subnet_1_name
  ip_range_pods              = "${var.subnet_1_name}-pod-cidr"
  ip_range_services          = "${var.subnet_1_name}-svc-cidr"
  config_connector           = true
  enable_private_endpoint    = false
  enable_private_nodes       = true
  master_ipv4_cidr_block     = "172.16.0.0/28"
}

module "workload_identity_1" {
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 16.0.1"
  gcp_sa_name         = "cnrmsa"
  cluster_name        = module.gke_1.name
  name                = "cnrm-controller-manager"
  location            = var.zone_1
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
  namespace           = "cnrm-system"
  project_id          = var.project_id
  roles               = ["roles/owner"]
}

#Module to create Fleet memebership and install ASM on GKE cluster
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

module "asm_1" {
  source = "git::https://github.com/terraform-google-modules/terraform-google-kubernetes-engine.git//modules/asm?ref=v20.0.0"
  cluster_name     = module.gke_1.name
  cluster_location = var.region_1
  project_id = var.project_id
  enable_cni = var.enable_cni

}