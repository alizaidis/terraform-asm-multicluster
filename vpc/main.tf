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

module "asmvpc" {
  source  = "terraform-google-modules/network/google"
  version = "5.0"

  project_id   = var.project_id
  network_name = var.vpc
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "${var.subnet_1_name}"
      subnet_ip     = "${var.subnet_1_ip}"
      subnet_region = "${var.region_1}"
      subnet_private_access = "true"
    }
    ,
    {
      subnet_name   = "${var.subnet_2_name}"
      subnet_ip     = "${var.subnet_2_ip}"
      subnet_region = "${var.region_2}"
      subnet_private_access = "true"
    }
  ]

  secondary_ranges = {
    "${var.subnet_1_name}" = [
      {
        range_name    = "${var.subnet_1_name}-pod-cidr"
        ip_cidr_range = "${var.pod_1_cidr}"
      },
      {
        range_name    = "${var.subnet_1_name}-svc-cidr"
        ip_cidr_range = "${var.svc_1_cidr}"
      }
    ]
    "${var.subnet_2_name}" = [
      {
        range_name    = "${var.subnet_2_name}-pod-cidr"
        ip_cidr_range = "${var.pod_2_cidr}"
      },
      {
        range_name    = "${var.subnet_2_name}-svc-cidr"
        ip_cidr_range = "${var.svc_2_cidr}"
      }
    ]
  }

  firewall_rules = [{
    name        = "allow-all-10"
    description = "Allow Pod to Pod connectivity"
    direction   = "INGRESS"
    ranges      = ["10.0.0.0/8"]
    allow = [{
      protocol = "tcp"
      ports    = ["0-65535"]
    }]
  }]
}


resource "google_compute_router" "router_1" {
  name    = "${var.region_1}-router"
  region  = var.region_1
  network = var.vpc
  bgp {
    advertise_mode     = "DEFAULT"
    advertised_groups  = []
    asn                = 64514
    keepalive_interval = 20
    }

  depends_on = [module.asmvpc]
}

resource "google_compute_router" "router_2" {
  name    = "${var.region_2}-router"
  region  = var.region_2
  network = var.vpc
  bgp {
    advertise_mode     = "DEFAULT"
    advertised_groups  = []
    asn                = 64514
    keepalive_interval = 20
    }

  depends_on = [module.asmvpc]
}

resource "google_compute_address" "address_region_1" {
  count  = 1
  name   = "nat-ip-${var.region_1}-${count.index}"
  region = var.region_1
  depends_on = [module.asmvpc]
}

resource "google_compute_address" "address_region_2" {
  count  = 1
  name   = "nat-ip-${var.region_2}-${count.index}"
  region = var.region_2
  depends_on = [module.asmvpc]
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
  depends_on = [module.asmvpc]
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
  depends_on = [module.asmvpc]
}

resource "null_resource" "enable_mesh" {

  provisioner "local-exec" {
    when    = create
    command = "echo y | gcloud container hub mesh enable --project ${var.project_id}"
  }
}