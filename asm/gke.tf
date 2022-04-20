#Module to create GKE cluster and enable APIs

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

# Resource blocks for Cloud NAT related objects for private notes in the GKE clusters.
resource "google_compute_router" "router_1" {
  name    = "${var.region_1}-router"
  region  = var.region_1
  network = var.vpc
}

resource "google_compute_router" "router_2" {
  name    = "${var.region_2}-router"
  region  = var.region_2
  network = var.vpc
}

resource "google_compute_address" "address_region_1" {
  count  = 1
  name   = "nat-ip-${var.region_1}-${count.index}"
  region = var.region_1
}

resource "google_compute_address" "address_region_2" {
  count  = 1
  name   = "nat-ip-${var.region_2}-${count.index}"
  region = var.region_2
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
}