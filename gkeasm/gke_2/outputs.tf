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

output "cluster_2_location" {
  value = module.gke_2.location
}

output "cluster_2_name" {
  value = module.gke_2.name
}

# output "workload_identity_2_email" {
#   description = "workload_identity_2 GCP service account email."
#   value       = module.workload_identity_2.gcp_service_account.email
# }

# output "workload_identity_2_ksa_name" {
#   description = "workload_identity_2 K8S SA name"
#   value       = module.workload_identity_2.k8s_service_account_name
# }