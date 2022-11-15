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
  project = var.create_project ? {
    project_id = try(module.project.0.project_id, null)
    number     = try(module.project.0.project_number, null)
    name       = try(module.project.0.project_name, null)
    } : {
    project_id = try(data.google_project.existing_project.0.project_id, null)
    number     = try(data.google_project.existing_project.0.number, null)
    name       = try(data.google_project.existing_project.0.name, null)
  }

  project_services = [
    "storage.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "iap.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com"
  ]

  project_admin_roles = [
    "roles/compute.loadBalancerAdmin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/artifactregistry.admin",
    "roles/run.admin",
    "roles/secretmanager.admin",
    "roles/cloudbuild.builds.editor",
    "roles/storage.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iap.admin",
    "roles/compute.instanceAdmin",
    "roles/iam.roleAdmin",
    "roles/oauthconfig.editor"
  ]
}

data "google_project" "existing_project" {
  count      = var.create_project ? 0 : 1
  project_id = var.project_name
}

resource "google_project_service" "default" {
  for_each = var.create_project ? [] : toset(local.project_services)
  project  = local.project.project_id
  service  = each.value

  disable_dependent_services = true
  disable_on_destroy         = true
}

module "project" {
  count   = var.create_project ? 1 : 0
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 14.0"

  name              = var.project_name
  random_project_id = true
  org_id            = var.organization_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account_id
  activate_apis     = local.project_services
}

resource "google_project_iam_member" "project_viewers" {
  for_each = var.project_viewers
  project  = local.project.project_id
  member   = each.value
  role     = "roles/viewer"

  depends_on = [
    google_project_service.default
  ]
}

resource "google_storage_bucket" "cloud_build_staging_bucket" {
  project                     = local.project.project_id
  location                    = var.region
  name                        = "${local.project.project_id}-cloud-build-staging"
  force_destroy               = true
  uniform_bucket_level_access = true

  depends_on = [
    google_project_service.default
  ]
}

resource "google_storage_bucket_iam_member" "cloud_build_staging_bucket_access" {
  bucket = google_storage_bucket.cloud_build_staging_bucket.name
  member = "serviceAccount:${google_service_account.service_identity.email}"
  role   = "roles/storage.objectAdmin"

  depends_on = [
    google_project_service.default
  ]
}

resource "google_storage_bucket" "static_asset_storage_bucket" {
  project                     = local.project.project_id
  name                        = "${local.project.project_id}-static-hosting"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "403.html"
  }

  cors {
    origin          = var.cors_origin
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  depends_on = [
    google_project_service.default
  ]
}

resource "google_storage_bucket_object" "modules" {
  for_each = var.upload_sample_content ? toset(["one", "two"]) : []
  name     = "module_${each.value}/index.html"
  bucket   = google_storage_bucket.static_asset_storage_bucket.name

  content = templatefile("${path.module}/static/sample_index.html", {
    NAME = each.value
  })

  depends_on = [
    google_project_service.default
  ]
}

resource "google_storage_bucket_object" "index_page" {
  bucket = google_storage_bucket.static_asset_storage_bucket.name
  name   = "index.html"
  source = "${path.module}/static/index.html"
}

resource "google_storage_bucket_object" "not_found_page" {
  bucket = google_storage_bucket.static_asset_storage_bucket.name
  name   = "403.html"
  source = "${path.module}/static/403.html"
}

resource "google_storage_bucket_iam_member" "cdn_access" {
  bucket = google_storage_bucket.static_asset_storage_bucket.name
  member = "serviceAccount:service-${local.project.number}@cloud-cdn-fill.iam.gserviceaccount.com"
  role   = "roles/storage.objectViewer"

  depends_on = [
    google_compute_backend_bucket_signed_url_key.signed_key
  ]
}

resource "google_project_iam_member" "project_admin_permission" {
  for_each = var.create_project ? [] : toset(local.project_admin_roles)
  member   = "user:${var.project_admin}"
  project  = local.project.project_id
  role     = each.value
}