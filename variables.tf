variable "project_id" {
    type= string
}
variable "google_compute_network" {
  type = string
}
variable "google_compute_global_address" {
    type = string
}
variable "region" {
    type = string
}
variable"google_apigee_instance"{
    type = string
}
variable"regions"{
    type =  type = map(object({
    regions = list(string)
    })
          default = {}
}
variable "google_apigee_environment" {
    type = string
}
variable "google_apigee_envgroup" {
    type = string
}
variable "google_compute_region_backend_service" {
    type = string
}
variable "google_compute_health_check" {
    type = string
}
variable "google_compute_forwarding_rule" {
    type = string
}
