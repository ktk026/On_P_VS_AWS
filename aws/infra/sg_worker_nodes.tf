resource "aws_security_group" "eks_worker_sg" {
  name   = "eks-worker-sg"
  vpc_id = aws_vpc.main.id

  tags = { Name = "app-eks-worker-sg" }
}


resource "aws_security_group_rule" "worker_ingress_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.eks_worker_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.my_ips
}

resource "aws_security_group_rule" "ingress_worker_to_worker" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_worker_sg.id
}






resource "aws_security_group_rule" "ingress_alb_to_worker_API" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
}
resource "aws_security_group_rule" "ingress_alb_to_worker_Front" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
}





resource "aws_security_group_rule" "ingress_monitoring__Node_Exporter" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.monitoring_sg.id
}
resource "aws_security_group_rule" "ingress_monitoring__Prometheus" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.monitoring_sg.id
}







resource "aws_security_group_rule" "egress_all_worker_nodes" {
  type              = "egress"
  security_group_id = aws_security_group.eks_worker_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}
