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

FROM alpine:3.15.4

RUN apk --update add --no-cache \
coreutils \
curl \
gettext \
jq \
openssl \
python3 \
unzip \
wget

ENV TERRAFORM_VERSION=1.1.7

# Install terraform
RUN echo "INSTALL TERRAFORM v${TERRAFORM_VERSION}" \
&& wget -q -O terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
&& unzip terraform.zip \
&& chmod +x terraform \
&& mv terraform /usr/local/bin \
&& rm -rf terraform.zip

# Install additional tools
# RUN gcloud components install \
# kpt \
# kubectl \
# alpha \
# beta \
# && rm -rf $(find google-cloud-sdk/ -regex ".*/__pycache__") \
# && rm -rf google-cloud-sdk/.install/.backup
