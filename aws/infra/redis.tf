resource "aws_instance" "redis" {
  ami                    = "ami-0d1f572dd6c60329d"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.db_2a.id
  vpc_security_group_ids = [aws_security_group.redis_sg.id]
  key_name               = var.key_name

  user_data = base64encode(<<-EOF
    #!/bin/bash
    systemctl daemon-reload
    systemctl enable redis-server
    systemctl restart redis-server
  EOF
  )

  tags = { Name = "app-redis" }
}
