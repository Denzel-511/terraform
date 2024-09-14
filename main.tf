# Declare variables for GCP credentials, project ID, and region
variable "GOOGLE_APPLICATION_CREDENTIALS" {
  description = "Path to the service account key file"
  type        = string
}

variable "GCP_PROJECT_ID" {
  description = "Google Cloud project ID"
  type        = string
}

variable "GCP_REGION" {
  description = "Google Cloud region"
  type        = string
}

# Define the Google Cloud provider
provider "google" {
  credentials = file(var.GOOGLE_APPLICATION_CREDENTIALS)
  project     = var.GCP_PROJECT_ID
  region      = var.GCP_REGION
}

# Reference an existing GCS bucket (replace with your bucket name)
data "google_storage_bucket" "existing_bucket" {
  name = "simplllle-bucket"
}

# IAM member to allow public access to the bucket
resource "google_storage_bucket_iam_member" "public_access" {
  bucket = data.google_storage_bucket.existing_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Backend bucket pointing to the existing GCS bucket for CDN integration
resource "google_compute_backend_bucket" "website_backend" {
  name        = "website-backend-bucket"
  bucket_name = data.google_storage_bucket.existing_bucket.name
  enable_cdn  = true # Enable Cloud CDN
}

# URL map for routing requests to the backend bucket
resource "google_compute_url_map" "website_url_map" {
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website_backend.id
}

# Target HTTP proxy to handle requests
resource "google_compute_target_http_proxy" "website_http_proxy" {
  name    = "website-http-proxy"
  url_map = google_compute_url_map.website_url_map.id
}

# Global forwarding rule for handling HTTP traffic (can be modified to HTTPS)
resource "google_compute_global_forwarding_rule" "website_forwarding_rule" {
  name       = "website-forwarding-rule"
  target     = google_compute_target_http_proxy.website_http_proxy.id
  port_range = "80"
  ip_protocol = "TCP"
}

# Output the website URL using Cloud CDN and Load Balancer's global IP
output "cdn_website_url" {
  value = "http://${google_compute_global_forwarding_rule.website_forwarding_rule.ip_address}"
}