resource "google_compute_firewall" "pidalio" {
  name    = "pidalio"
  network = "pidalio"

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_tags = ["pidalio"]
  source_ranges = ["0.0.0.0/0"]

  depends_on = ["google_compute_network.pidalio"]
}
