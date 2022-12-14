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

locals {
  full_image_name      = "${var.region}-docker.pkg.dev/${local.project.project_id}/${google_artifact_registry_repository.login_app_registry.name}/static-hosting-login"
  cloud_build_identity = "${local.project.number}@cloudbuild.gserviceaccount.com"
  image_tag            = var.image_tag == null ? data.external.git_tag.result.tag : var.image_tag
}

data "external" "git_tag" {
  program = ["bash", "${path.module}/scripts/img-tag.sh"]
}

resource "google_artifact_registry_repository_iam_member" "cloud_build_access" {
  project    = local.project.project_id
  member     = "serviceAccount:${local.cloud_build_identity}"
  repository = google_artifact_registry_repository.login_app_registry.name
  role       = "roles/artifactregistry.writer"
  location   = var.region
}

resource "google_artifact_registry_repository" "login_app_registry" {
  provider      = google-beta
  project       = local.project.project_id
  format        = "DOCKER"
  repository_id = var.artifact_registry_repository_id
  location      = var.region
  description   = "Artifact Registry repository to store the Cloud Run application image"

  depends_on = [
    google_project_service.default
  ]
}

module "login_app_image" {
  source = "./modules/login-app"

  project_id                = local.project.project_id
  image_name                = local.full_image_name
  image_tag                 = local.image_tag
  region                    = var.region
  cloudbuild_storage_bucket = google_storage_bucket.cloud_build_staging_bucket.name
}
