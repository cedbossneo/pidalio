resource "google_compute_network" "pidalio" {
  name       = "pidalio"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "pidalio-node" {
  name          = "pidalio-node"
  ip_cidr_range = "10.1.1.0/24"
  network       = "${google_compute_network.pidalio.self_link}"
}

output "subnet" {
  value = "${google_compute_subnetwork.pidalio-node.name}"
}