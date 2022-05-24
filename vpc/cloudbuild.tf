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

# resource "google_project_iam_member" "cloudbuild_sa_owner" {
#   project = var.project_id
#   role    = "roles/owner"
#   member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
# }


# resource "google_artifact_registry_repository" "platform-installer" {
#   provider = google-beta

#   location = var.region_1
#   repository_id = "platform-installer"
#   description = "Repo for platform installer container images built by Cloud Build."
#   format = "DOCKER"
# }

resource "google_artifact_registry_repository_iam_member" "cloud-build-member" {
  provider = google-beta

  location = var.region_1
  repository = "platform-installer"
  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}