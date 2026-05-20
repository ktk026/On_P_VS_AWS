resource "aws_instance" "monitoring_server" {
  ami                         = data.aws_ami.ubuntu_eks.id
  instance_type               = "t3.medium"
  vpc_security_group_ids      = [aws_security_group.monitoring_sg.id]
  subnet_id                   = aws_subnet.public_2a.id
  associate_public_ip_address = true

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y prometheus grafana
    systemctl enable --now prometheus grafana-server
  EOF
  )

  tags = {
    Name = "Monitoring-Server"
  }
}