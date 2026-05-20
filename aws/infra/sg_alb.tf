resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  tags = { Name = "app-alb-sg" }
}


resource "aws_security_group_rule" "ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_locust" {
  type                     = "ingress"
  security_group_id        = aws_security_group.alb_sg.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.locust_sg.id
}

resource "aws_security_group_rule" "ingress_monitoring" {
  type = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  from_port = 9106    # CloudWatch 표준 포트
  to_port = 9106
  protocol = "tcp"
  source_security_group_id = aws_security_group.monitoring_sg.id
}


resource "aws_security_group_rule" "egress_alb_to_worker" {
  type = "egress"
  security_group_id = aws_security_group.alb_sg.id
  from_port = 30000
  to_port = 32767
  protocol = "tcp"
  source_security_group_id = aws_security_group.eks_worker_sg.id
}