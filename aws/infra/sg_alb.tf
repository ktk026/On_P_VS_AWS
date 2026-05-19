resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  tags = { Name = "app-alb-sg" }
}

resource "aws_security_group_rule" "ingress_http" {
  type                     = "ingress"
  security_group_id        = aws_security_group.alb_sg.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.locust_sg.id
}

resource "aws_security_group_rule" "ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_to_API" {
  type                     = "egress"
  security_group_id        = aws_security_group.alb_sg.id
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker_sg.id
}
resource "aws_security_group_rule" "egress_to_Front" {
  type                     = "egress"
  security_group_id        = aws_security_group.alb_sg.id
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker_sg.id
}


# Health Check 막힐 경우
#
# resource "aws_security_group_rule" "alb_egress_all" {
#   type              = "egress"
#   security_group_id = aws_security_group.alb_sg.id
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
# }
