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

resource "google_compute_global_address" "https_lb_ip_address" {
  project      = local.project.project_id
  name         = "${var.load_balancer_name}-address"
  ip_version   = "IPV4"
  description  = "Public IP address of the load balancer."
  address_type = "EXTERNAL"

  depends_on = [
    google_project_service.default
  ]
}

resource "google_compute_managed_ssl_certificate" "lb_ssl_certificate" {
  project = local.project.project_id
  name    = "storage-ssl-cert"

  managed {
    domains = var.ssl_domain_names
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    google_project_service.default
  ]
}

resource "google_compute_backend_bucket" "backend" {
  project     = local.project.project_id
  bucket_name = google_storage_bucket.static_asset_storage_bucket.name
  name        = "${var.load_balancer_name}-backend-bucket"
  enable_cdn  = true

  depends_on = [
    google_project_service.default
  ]
}

resource "google_compute_backend_bucket_signed_url_key" "signed_key" {
  project        = local.project.project_id
  name           = var.cdn_signing_url_key_name
  backend_bucket = google_compute_backend_bucket.backend.name
  key_value      = var.cdn_signing_key

  depends_on = [
    google_project_service.default
  ]
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  project    = local.project.project_id
  name       = "${var.load_balancer_name}-fwd-rule"
  target     = google_compute_target_https_proxy.static_proxy.id
  ip_address = google_compute_global_address.https_lb_ip_address.self_link
  port_range = "443"

  depends_on = [
    google_project_service.default
  ]
}

resource "google_compute_ssl_policy" "ssl_policy" {
  project         = local.project.project_id
  name            = "${var.load_balancer_name}-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"

  depends_on = [
    google_project_service.default
  ]
}

resource "google_compute_target_https_proxy" "static_proxy" {
  project          = local.project.project_id
  name             = "${var.load_balancer_name}-target-proxy"
  ssl_certificates = [google_compute_managed_ssl_certificate.lb_ssl_certificate.id]
  url_map          = google_compute_url_map.lb_url_map.id
  ssl_policy       = google_compute_ssl_policy.ssl_policy.id

  depends_on = [
    google_project_service.default
  ]
}

resource "google_compute_url_map" "lb_url_map" {
  project         = local.project.project_id
  name            = "${var.load_balancer_name}-static-bucket-map"
  default_service = google_compute_backend_bucket.backend.id

  host_rule {
    hosts        = var.ssl_domain_names
    path_matcher = "cdn-cookie-matcher"
  }

  path_matcher {
    name            = "cdn-cookie-matcher"
    default_service = google_compute_backend_bucket.backend.id

    route_rules {
      priority = 1
      match_rules {
        prefix_match = "/"
        header_matches {
          header_name  = "cookie"
          prefix_match = "Cloud-CDN-Cookie"
        }

      }
      service = google_compute_backend_bucket.backend.id
    }

    route_rules {
      priority = 2
      match_rules {
        prefix_match = "/"
      }

      service = google_compute_backend_service.login_app_service.id
    }
  }

  depends_on = [
    google_project_service.default
  ]
}

# HTTP Redirect
resource "google_compute_url_map" "static_http_map" {
  project = local.project.project_id
  name    = "${var.load_balancer_name}-http-url-map"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }

  depends_on = [
    google_project_service.default
  ]
}

resource "google_compute_target_http_proxy" "http_to_https_redirect" {
  project = local.project.project_id
  name    = "${var.load_balancer_name}-static-http-proxy"
  url_map = google_compute_url_map.static_http_map.id

  depends_on = [
    google_project_service.default
  ]
}

resource "google_compute_global_forwarding_rule" "static_http" {
  project    = local.project.project_id
  name       = "${var.load_balancer_name}-forwarding-rule-http"
  target     = google_compute_target_http_proxy.http_to_https_redirect.id
  port_range = "80"
  ip_address = google_compute_global_address.https_lb_ip_address.id
}