/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "cloudbuild_storage_bucket" {
  description = "Bucket that should be used by Cloud Build to store the artifacts"
  type        = string
}

variable "image_name" {
  description = "Name of the container image."
  type        = string
}

variable "image_tag" {
  description = "Tag to be used for the image."
  type        = string
}

variable "project_id" {
  description = "Project ID where the image will be pushed and stored."
  type        = string
}

variable "region" {
  description = "Region where the Cloud Build should run"
  type        = string
}

