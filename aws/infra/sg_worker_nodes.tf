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
  self = true
}

resource "aws_security_group_rule" "ingress_kubelet" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  self = true
}




resource "aws_security_group_rule" "ingress_public_to_worker" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}







resource "aws_security_group_rule" "ingress_monitoring_api" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.monitoring_sg.id
}
resource "aws_security_group_rule" "ingress_monitoring_services" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 4001
  to_port                  = 4005
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.monitoring_sg.id
}
resource "aws_security_group_rule" "ingress_locust" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_worker_sg.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.locust_sg.id
}

resource "aws_security_group_rule" "ingress_monitoring" {
  type = "ingress"
  security_group_id = aws_security_group.eks_worker_sg.id
  from_port = 9106    # CloudWatch 표준 포트
  to_port = 9106
  protocol = "tcp"
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
