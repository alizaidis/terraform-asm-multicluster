#Terraform providers to use
terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "3.90.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.10.0"
    }
  }
}
provider "google-beta" {
  project = var.project_id
  region  = var.region_1
  zone    = var.zone_1
}