#Terraform providers to use
terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "3.90.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.17.0"
    }
  }
}

provider "google-beta" {
  project = var.project_id
  region  = var.region_1
  zone    = var.zone_1
}

provider "google" {
  project = var.project_id
  region  = var.region_1
  zone    = var.zone_1
}