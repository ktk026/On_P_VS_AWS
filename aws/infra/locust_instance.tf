resource "aws_instance" "locust_server" {
  ami                         = data.aws_ami.ubuntu_eks.id
  instance_type               = "t3.medium"
  vpc_security_group_ids      = [aws_security_group.locust_sg.id]
  subnet_id                   = aws_subnet.public_2a.id
  associate_public_ip_address = true

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y python3-pip python3-venv
    pip3 install locust
    cat << 'PYEOF' > /home/ubuntu/locustfile.py
    from locust import HttpUser, task, between

    class QuickstartUser(HttpUser):
        wait_time = between(1, 2)
        @task
        def index(self):
            self.client.get("/")
    PYEOF
  EOF
  )

  tags = {
    Name = "Locust-Server"
  }
}