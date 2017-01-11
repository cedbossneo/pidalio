provider "google" {
  credentials = "${file("/Users/cedric/Downloads/sandbox-wescale-1eb3c50a216b.json")}"
  project     = "sandbox-wescale"
  region      = "europe-west1"
}

resource "random_id" "token" {
  byte_length = 16
}

module "google" {
  source = "../../modules/google"
  instance_type = "n1-standard-2"
  token = "${random_id.token.hex}"
  ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCwrZA+XB29C7VeRMur/BUrLZ6zlu4Ajl2KVvLmc7MtmfWCujyIVrXfPdRzUZT+rXmDN1Nzm7OxCy0V7cR2+GswiLUacOpCVddED7Tb3OWK/C1PcNw2N7aIpREkjaP3tFVVQ3/FvIkQdtkn0AX7dXhVyOwIQCteanRKhCv9K1tI7muUy01r/kb9uOIrzqUzLy4sz1LJrTSLLFge4ORiLJlh9RtkAP2t9KcSZPZQisbzGyIdr8YlvWQUIbRGhelc9v92cfKxlSGo/OWWmHvwUfrmjKzzHdH4fwmD9N0zoKggFQexzSZsz43PFVfazobxWBEkwTlfQhkmnm1Y+o7TIgXz cedric@MacBook-Pro-de-Cedric-Pro.local"
  zone = "europe-west1-c"
  region = "europe-west1"
  peers = "10.1.1.2 10.1.1.3 10.1.1.4 10.1.1.5"
}

