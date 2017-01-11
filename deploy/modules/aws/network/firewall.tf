resource "aws_security_group" "pidalio" {
  name = "pidalio"
  network = "pidalio"

}

resource "aws_security_group_rule" "pidalio-allow-inbound" {
  from_port = 0
  to_port = 65535
  protocol = "-1"
  security_group_id = "${aws_security_group.pidalio.id}"
  type = "ingress"
  cidr_blocks = ["0.0.0.0/0"]

  depends_on = ["aws_security_group.pidalio"]
}

resource "aws_security_group_rule" "pidalio-allow-outbound" {
  from_port = 0
  to_port = 65535
  protocol = "-1"
  security_group_id = "${aws_security_group.pidalio.id}"
  type = "egress"
  cidr_blocks = ["0.0.0.0/0"]

  depends_on = ["aws_security_group.pidalio"]
}
