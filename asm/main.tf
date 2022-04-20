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

module "asm_1" {
  source = "git::https://github.com/terraform-google-modules/terraform-google-kubernetes-engine.git//modules/asm?ref=v20.0.0"
  cluster_name     = module.gke_1.name
  cluster_location = var.region_1
  project_id = var.project_id
  enable_cni = var.enable_cni

}

module "asm_2" { 
  source = "git::https://github.com/terraform-google-modules/terraform-google-kubernetes-engine.git//modules/asm?ref=v20.0.0"  
  cluster_name     = module.gke_2.name
  cluster_location = var.region_2
  project_id = var.project_id
  enable_cni = var.enable_cni

}