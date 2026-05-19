resource "aws_security_group" "rds_sg" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id
  tags   = { Name = "app-rds-sg" }
}

resource "aws_security_group_rule" "ingress_postgres_from_worker" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds_sg.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker_sg.id
}

resource "aws_security_group_rule" "ingress_from_monitoring" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds_sg.id
  from_port                = 9187
  to_port                  = 9187
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.monitoring_sg.id
}
