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

variable "project_id" {
  type        = string
  description = "The GCP project where the cluster will be created"
}

variable "region_1" {
  type        = string
  description = "The GCP region where cluster 1 will be created"
  default = "us-west1"
}

variable "zone_1" {
  type        = string
  description = "The GCP zone in the region where cluster 1 will be created"
  default     = "us-west1-b"
}

variable "region_2" {
  type        = string
  description = "The GCP region where cluster 2 will be created"
  default = "us-central1"
}

variable "zone_2" {
  type        = string
  description = "The GCP zone in the region where cluster 2 will be created"
  default     = "us-central1-c"
}

variable "vpc" {
  type        = string
  description = "The VPC network where the clusters will be created"
  default     = "asm-tutorial"
}

variable "subnet_1_name" {
  type        = string
  description = "The subnet where cluster 1 will be created"
  default = "subnet-west"
}

variable "subnet_1_ip" {
  type    = string
  default = "10.128.0.0/20"
}

variable "pod_1_cidr" {
  type        = string
  description = "CIDR range for Pods"
  default = "10.76.0.0/14"
}

variable "svc_1_cidr" {
  type        = string
  description = "CIDR range for services"
  default = "10.80.0.0/20"
}

variable "subnet_2_name" {
  type        = string
  description = "The subnet where cluster 2 will be created"
  default = "subnet-central"
}

variable "subnet_2_ip" {
  type    = string
  default = "10.168.0.0/20"
}

variable "pod_2_cidr" {
  type        = string
  description = "CIDR range for Pods"
  default = "10.12.0.0/14"
}

variable "svc_2_cidr" {
  type        = string
  description = "CIDR range for services"
  default = "10.16.0.0/20"
}

variable "gke_1_name" {
  type = string
  default = "asm-cluster-1"
}

variable "gke_2_name" {
  type = string
  default = "asm-cluster-2"
}

variable "gke_channel" {
  type = string
  default = "REGULAR"
}

variable "enable_cni" {
  type = bool
  default = "true"
}
