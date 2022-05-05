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

data "google_project" "project" {
}

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
    no_external_ip = false
  }
  network_config {
    peered_network = module.asmvpc.network_id
  }
  depends_on = [google_service_networking_connection.worker_pool_conn]
}

resource "google_cloudbuild_trigger" "service-account-trigger" {
  source_to_build {
    uri       = "https://github.com/alizaidis/terraform-asm-multicluster"
    ref       = "refs/heads/main"
    repo_type = "GITHUB"
  }
  build {
    timeout = "3600s"
    step {
      name = "gcr.io/kaniko-project/executor:v1.6.0"
      id = "build-installer-image"
      args = ["--destination=us-west1-docker.pkg.dev/${var.project_id}/platform-installer/installer", "--cache=true", "--cache-ttl=12h"]
      timeout = "120s"
    }
    step {
      name = "us-west1-docker.pkg.dev/${var.project_id}/platform-installer/installer"
      id = "gke-asm-terraform"
      dir = "asm"
      entrypoint = "bash"
      args = ["-xe", "-c", "echo \"project_id = ${var.project_id}\" > terraform.tfvars", "terraform init -backend-config=\"bucket=${var.project_id}-tfstate\"", "terraform plan -out terraform.tfplan", "terraform apply -input=false -lock=false terraform.tfplan"]
      timeout = "1200s"
    }
    options {
        worker_pool = "projects/${var.project_id}/workerPools/${google_cloudbuild_worker_pool.private-build-pool.name}"
        logging = "STACKDRIVER_ONLY"
    }
  }
  service_account = google_service_account.cloudbuild_trigger_sa.id
  project = var.project_id
  depends_on = [
    google_project_iam_member.act_as,
    google_project_iam_member.logs_writer
  ]
}

resource "google_project_iam_member" "cloudbuild_sa_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  depends_on = [module.enabled_google_apis]
}

resource "google_service_account" "cloudbuild_trigger_sa" {
  account_id = "terraform-cloud-build"
  project = var.project_id
}

resource "google_project_iam_member" "act_as" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloudbuild_trigger_sa.email}"
}

resource "google_project_iam_member" "logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudbuild_trigger_sa.email}"
}

resource "google_project_iam_member" "cloudbuild_trigger_sa_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.cloudbuild_trigger_sa.email}"
}

resource "google_artifact_registry_repository" "platform-installer" {
  provider = google-beta

  location = var.region_1
  repository_id = "platform-installer"
  description = "Repo for platform installer container images built by Cloud Build."
  format = "DOCKER"
  depends_on = [time_sleep.wait_120_seconds, module.enabled_google_apis]
}

resource "google_artifact_registry_repository_iam_member" "cloud-build-member" {
  provider = google-beta

  location = google_artifact_registry_repository.platform-installer.location
  repository = google_artifact_registry_repository.platform-installer.name
  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.cloudbuild_trigger_sa.email}"
}