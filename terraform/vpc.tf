# Module to create VPC for the GKE cluster
module "asm-vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 4.0"

  project_id   = var.project_id
  network_name = var.vpc
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name   = "${var.subnet_1_name}"
      subnet_ip     = "${var.subnet_1_ip}"
      subnet_region = "${var.region_1}"
    }
    ,
    {
      subnet_name   = "${var.subnet_2_name}"
      subnet_ip     = "${var.subnet_2_ip}"
      subnet_region = "${var.region_2}"
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
  depends_on = [time_sleep.wait_120_seconds]
}