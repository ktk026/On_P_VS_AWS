resource "aws_security_group" "monitoring_sg" {
  name   = "monitoring-sg"
  vpc_id = aws_vpc.main.id

  tags = { Name = "app-monitoring-sg" }
}

resource "aws_security_group_rule" "ingress_from_Front" {
  type              = "ingress"
  security_group_id = aws_security_group.monitoring_sg.id
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = var.my_ips
}

resource "aws_security_group_rule" "monitoring_server_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.monitoring_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.my_ips
}

resource "aws_security_group_rule" "egress_all_monitoring" {
  type              = "egress"
  security_group_id = aws_security_group.monitoring_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
