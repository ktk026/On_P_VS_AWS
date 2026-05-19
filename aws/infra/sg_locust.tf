resource "aws_security_group" "locust_sg" {
  name   = "locust-sg"
  vpc_id = aws_vpc.main.id
  tags   = { Name = "app-locust-sg" }
}

resource "aws_security_group_rule" "ingress_locust_web" {
  type              = "ingress"
  security_group_id = aws_security_group.locust_sg.id
  from_port         = 8089
  to_port           = 8089
  protocol          = "tcp"
  cidr_blocks       = var.my_ips
}

resource "aws_security_group_rule" "locust_ingress_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.locust_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.my_ips
}

resource "aws_security_group_rule" "egress_all_locust" {
  type              = "egress"
  security_group_id = aws_security_group.locust_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
