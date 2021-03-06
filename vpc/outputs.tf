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

output "network_name" {
  value = module.asmvpc.network_name
}

output "subnet_names" {
  value = module.asmvpc.subnets_names
}

output "subnets_regions" {
  value = module.asmvpc.subnets_regions
}

output "cloud_build_worker_pool_name" {
  value = google_cloudbuild_worker_pool.private-build-pool.name
}