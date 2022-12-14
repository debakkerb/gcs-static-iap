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

resource "google_secret_manager_secret" "cdn_signing_key" {
  project   = local.project.project_id
  secret_id = var.cdn_signing_key_secret_name

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  depends_on = [
    google_project_service.default
  ]
}

resource "google_secret_manager_secret_version" "cdn_signing_key_version" {
  secret      = google_secret_manager_secret.cdn_signing_key.id
  secret_data = var.cdn_signing_key
}

resource "google_secret_manager_secret_iam_member" "cdn_signing_key_access" {
  project   = local.project.project_id
  member    = "serviceAccount:${google_service_account.service_identity.email}"
  role      = "roles/secretmanager.secretAccessor"
  secret_id = google_secret_manager_secret.cdn_signing_key.id
}