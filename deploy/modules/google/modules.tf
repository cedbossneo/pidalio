variable instance_type {}
variable token {}
variable ssh_key {}
variable zone {}
variable region {}
variable peers {}

module "network" {
  source = "./network"
}

module "compute" {
  source = "./compute"
  peers = "${var.peers}"
  ssh_key = "${var.ssh_key}"
  token = "${var.token}"
  zone = "${var.zone}"
  region = "${var.region}"
  subnet = "${module.network.subnet}"
  instance_type = "${var.instance_type}"
}
