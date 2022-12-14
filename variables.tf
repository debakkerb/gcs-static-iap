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
variable "artifact_registry_repository_id" {
  description = "ID of the Artifact Registry repository"
  type        = string
  default     = "login-app-registry"
}

variable "billing_account_id" {
  description = "Billing Account ID that should be associated with the project."
  type        = string
}

variable "brand_application_title" {
  description = "Application title for the IAP configuration."
  type        = string
}

variable "brand_support_email" {
  description = "Support email address for the IAP configuration."
  type        = string
}

variable "cdn_signing_key_secret_name" {
  description = "Name of the secret where the signing key will be stored for the CDN cookie."
  type        = string
  default     = "cdn-sign-key"
}

variable "cdn_signing_key" {
  description = "value for the signing key.  If not set, a random value will be generated"
  type        = string
  default     = null
}

variable "cdn_signing_url_key_name" {
  description = "Name of the key to sign the CDN URLs"
  type        = string
  default     = "cdn-signed-url-key"
}

variable "cors_origin" {
  description = "Origin for the storage bucket."
  type        = list(string)
  default     = []
}

variable "create_project" {
  description = "Whether or not to create a project.  If set to false, a valid Project ID has to be supplied in `project_name`."
  type        = bool
  default     = true
}

variable "enable_backend_service_logging" {
  description = "Enable logging on the NEG backend service."
  type        = bool
  default     = true
}

variable "folder_id" {
  description = "Folder ID where the project should be created."
  type        = string
}

variable "iap_client_display_name" {
  description = "Display name for the IAP client."
  type        = string
}

variable "image_tag" {
  description = "Tag to be used for the image. If not set, the Git description will be used."
  type        = string
  default     = null
}

variable "load_balancer_name" {
  description = "Name of the load balancer."
  type        = string
  default     = "lb-static-tst"
}

variable "login_service_name" {
  description = "Name of the Cloud Run service that will create the cookie."
  type        = string
  default     = "login-service"
}

variable "login_service_access" {
  description = "A list of IAM identities who can access the service.  This can be a list of user:, groups:, domain:, ..."
  type        = set(string)
}

variable "region" {
  description = "Default regions for all resources."
  type        = string
  default     = "europe-west1"
}

variable "organization_id" {
  description = "Organization ID where the project should be created."
  type        = string
}

variable "project_admin" {
  description = "Identity of the user executing the Terraform commands to create the resources."
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Name of the project."
  type        = string
  default     = "static-hosting-tst"
}

variable "project_viewers" {
  description = "List of users who require Viewer access on the project."
  type        = set(string)
  default     = []
}

variable "remove_domain_restricted_sharing_policy" {
  description = "If Domain Restricted Sharing has been enabled, remove for this project."
  type        = bool
  default     = false
}

variable "ssl_domain_names" {
  description = "List of domains for the SSL certificate."
  type        = list(string)
}

variable "upload_sample_content" {
  description = "Upload sample content to the Cloud Storage bucket"
  type        = bool
  default     = false
}