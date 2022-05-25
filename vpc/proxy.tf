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

# data "google_compute_disk" "squid_image" {
#     name        = "projects/zaidilabs-build/global/images/squid-proxy-image"
#     project     = var.project_id
# }

resource "google_service_account" "squid_sa" {
  account_id   = "squid-sa"
  display_name = "Squid Service Account"
}

# resource "google_compute_global_address" "squid_address" {
#   name          = "squid-address"
#   address_type  = "INTERNAL"
#   network       = module.asmvpc.network_name
# }

resource "google_compute_instance" "squid_proxy" {
  name         = "squid-proxy"
  machine_type = "e2-medium"
  zone         = "us-west1-a"

  tags = ["squid"]

  boot_disk {
    initialize_params {
      image = "projects/zaidilabs-build/global/images/squid-proxy-image"
    }
  }

  network_interface {
    subnetwork = var.subnet_1_name
    network_ip = "10.128.12.8"
  }

  service_account {
    email  = google_service_account.squid_sa.email
    scopes = ["cloud-platform"]
  }
}


#   network_interface {
#     subnetwork = var.subnet_1_name
#     network_ip = google_compute_global_address.squid_address.address
#   }