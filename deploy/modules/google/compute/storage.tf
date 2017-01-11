resource "google_compute_instance_template" "instance_template_storage" {
  name        = "pidalio-storage"
  description = "Pidalio Storage"

  tags = ["pidalio"]

  region = "${var.region}"

  instance_description = "Pidalio Storage"
  machine_type         = "${var.instance_type}"
  can_ip_forward       = true

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "coreos-cloud/coreos-stable"
    auto_delete = true
    boot = true
  }

  disk {
    disk_type = "pd-standard"
    auto_delete = false
    device_name = "/dev/sdb"
    disk_size_gb = "500"
  }

  network_interface {
    subnetwork = "${var.subnet}"
    access_config {

    }
  }

  metadata {
    user-data = "${data.template_file.user_data_storage.rendered}"
    ssh-keys = "core:${var.ssh_key}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-rw", "storage-rw"]
  }

}

resource "google_compute_instance_group_manager" "instance_group_storage" {
  base_instance_name = "pidalio-node"
  instance_template = "${google_compute_instance_template.instance_template_storage.self_link}"
  name = "pidalio-nodes"
  target_size = "${var.nodes}"
  zone = "${var.zone}"

  depends_on = ["google_compute_instance_template.instance_template_storage"]
}

data "template_file" "user_data_storage" {
  template = "${file("${path.module}/cloud-config.yaml")}"

  vars {
    peers    = "${var.peers}"
    token    = "${var.token}"
    storage  = "true"
  }
}