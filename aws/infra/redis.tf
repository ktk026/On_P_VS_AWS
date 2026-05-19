resource "aws_instance" "redis" {
  ami                    = data.aws_ami.ubuntu_eks.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.db_2a.id
  vpc_security_group_ids = [aws_security_group.redis_sg.id]

  tags = { Name = "app-redis" }
}
