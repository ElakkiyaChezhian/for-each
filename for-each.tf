provider "google" {
    project = var.project_id
}
resource "google_compute_network" "apigee_network1" {
  name       = var.google_compute_network
}
resource "google_compute_global_address" "apigee_range1" {
  name          = var.google_compute_global_address
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.apigee_network1.id
}
resource "google_service_networking_connection" "apigee_vpc_connection" {
  network                 = google_compute_network.apigee_network1.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.apigee_range1.name]
}
locals {
    googleapis = [   "apigee.googleapis.com",
   "cloudkms.googleapis.com",
   "compute.googleapis.com",
   "servicenetworking.googleapis.com"
 ]
    regions = toset(["us-central1", "us-east4","us-east1"])
}
resource "google_project_service" "apis" {
     for_each           = toset(local.googleapis)
     project            = var.project_id
     service            = each.key 
     disable_on_destroy = false
     }
resource "google_apigee_organization" "apigeex_org" { 
  analytics_region   = var.region
  project_id         = var.project_id
  authorized_network = google_compute_network.apigee_network1.id
  depends_on         = [
    google_service_networking_connection.apigee_vpc_connection,
    //google_project_service.apis.apigee,
  ]
}
resource "google_apigee_environment" "apigee_org_region_env1" {
  name         = var.google_apigee_environment
  description  = "apigee-env-dev"
  display_name = "apigee-env-dev"
  org_id       = google_apigee_organization.apigeex_org.id
  instance_id  = google_apigee_instance.apigee_instance1.id
}
resource "google_apigee_envgroup" "env_grp_dev1" {
  name      = var.google_apigee_envgroup
  hostnames = ["grp.test.com"]
  org_id    = google_apigee_organization.apigeex_org.id
  instance_id  = google_apigee_instance.apigee_instance1.id
}
resource "google_apigee_instance" "apigee_instance1" {
for_each     = toset(local.regions)
name         = each.key
location     = each.value
org_id   = google_apigee_organization.apigeex_org.id
depends on   = [
    google_apigee_instance_attachment.instance_attachment,
    ]
}
resource "google_apigee_instance_attachment" "instance_attachment" {
  instance_id  = google_apigee_instance.apigee_instance1.id
  environment  = google_apigee_environment.apigee_org_region_env1.name
}
resource "google_compute_region_backend_service" "producer_service_backend1" {
  name          = var.google_compute_region_backend_service
  project       = var.project_id
  region        = var.region
  health_checks = [google_compute_health_check.producer_service_health_check1.id]
}
resource "google_compute_health_check" "producer_service_health_check1" {
  name                = var.google_compute_health_check
  project             = var.project_id
  check_interval_sec  = 1
  timeout_sec         = 1
  tcp_health_check {
    port = "80"
  }
}
resource "google_compute_forwarding_rule" "apigee_ilb_target_service1" {
   name                  = var.google_compute_forwarding_rule
   region                = var.region
   project               = var.project_id
   load_balancing_scheme = "INTERNAL"
   backend_service       = google_compute_region_backend_service.producer_service_backend1.id
   all_ports             = true
   network               = google_compute_network.apigee_network1.id
   //subnetwork            =    "projects/${google_compute_network.apigee_network.id}/regions/us-east1/subnetworks/prv-sn-1"
}
