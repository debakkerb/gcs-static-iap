#!/usr/bin/env bash

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

PROJECT_ID=$1
IMAGE_NAME=$2
IMAGE_TAG=$3
REGION=$4
SOURCE_STORAGE_BUCKET=$5

gcloud config set project ${PROJECT_ID}
gcloud builds submit . --pack image=${IMAGE_NAME}:${IMAGE_TAG} --region ${REGION} --gcs-source-staging-dir gs://${SOURCE_STORAGE_BUCKET}/source --gcs-log-dir gs://${SOURCE_STORAGE_BUCKET}/logs --suppress-logs
