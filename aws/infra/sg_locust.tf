resource "aws_security_group" "locust_sg" {
  name   = "locust-sg"
  vpc_id = aws_vpc.main.id
  tags   = { Name = "app-locust-sg" }
}


resource "aws_security_group_rule" "ingress_locust_ssh" {
  type = "ingress"
  security_group_id = aws_security_group.locust_sg.id
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = var.my_ips
}


resource "aws_security_group_rule" "egress_all_locust" {
  type              = "egress"
  security_group_id = aws_security_group.locust_sg.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = aws_security_group.eks_worker_sg.id
}
