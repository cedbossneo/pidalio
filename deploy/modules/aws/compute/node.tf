variable "nodes"             { default = 3 }
variable "instance_type"     { }
variable "image"               { }
variable "key_name"          { }
variable "subnet"            { }
variable "peers"             { }
variable "token"             { }

resource "aws_launch_configuration" "instance_config" {
  count = "${var.nodes}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  subnet_id = "${var.subnet}"
  user_data = "${template_file.user_data.rendered}"
  image_id = "${var.image}"
}

resource "aws_autoscaling_group" "instance_group" {
  launch_configuration = "${aws_launch_configuration.instance_config.id}"
  max_size = 10
  min_size = 3
}

resource "template_file" "user_data" {
  template = "${path.module}/cloud-config.yaml"

  lifecycle { create_before_destroy = true }

  vars {
    peers    = "${var.peers}"
    token    = "${var.token}"
  }
}