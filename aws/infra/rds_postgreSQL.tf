resource "aws_db_subnet_group" "db_subnet_group" {
  name = "app-db-subnet-group"

  subnet_ids = [
    aws_subnet.db_2a.id,
    aws_subnet.db_2c.id
  ]
}

resource "aws_db_instance" "postgres" {
  identifier        = "app-postgres"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.medium"
  allocated_storage = 20

  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true

  availability_zone = "ap-northeast-2a"
}
