data "aws_ssm_parameter" "ubuntu_eks_ami" {
  name = "/aws/service/canonical/ubuntu/eks/24.04/${var.k8s_version}/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

locals {
  eks_node_user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    /etc/eks/bootstrap.sh "${aws_eks_cluster.eks.name}" \
      --b64-cluster-ca "${aws_eks_cluster.eks.certificate_authority[0].data}" \
      --apiserver-endpoint "${aws_eks_cluster.eks.endpoint}"

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl prometheus-node-exporter

    cat >/etc/default/prometheus-node-exporter <<'EOF'
    ARGS="--web.listen-address=:9106"
    EOF
    systemctl enable prometheus-node-exporter
    systemctl restart prometheus-node-exporter

    curl -fsSL -o /tmp/amazon-cloudwatch-agent.deb \
      https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    dpkg -i /tmp/amazon-cloudwatch-agent.deb || apt-get install -f -y

    cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOF'
    {
      "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
      },
      "metrics": {
        "namespace": "app-eks/nodes",
        "metrics_collected": {
          "cpu": {
            "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
            "metrics_collection_interval": 60,
            "totalcpu": true
          },
          "disk": {
            "measurement": ["used_percent"],
            "metrics_collection_interval": 60,
            "resources": ["*"]
          },
          "mem": {
            "measurement": ["mem_used_percent"],
            "metrics_collection_interval": 60
          },
          "swap": {
            "measurement": ["swap_used_percent"],
            "metrics_collection_interval": 60
          }
        }
      }
    }
    EOF

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  EOT
}

resource "aws_launch_template" "eks_api_nodes_template" {
  name_prefix   = "eks-api-node-"
  image_id      = data.aws_ssm_parameter.ubuntu_eks_ami.value
  instance_type = "t3.medium"
  key_name      = var.key_name

  vpc_security_group_ids = [
    aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id,
    aws_security_group.eks_worker_sg.id
  ]

  user_data = base64encode(local.eks_node_user_data)

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "eks-api-node-instance" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "eks_service_nodes_template" {
  name_prefix   = "eks-service-node-"
  image_id      = data.aws_ssm_parameter.ubuntu_eks_ami.value
  instance_type = "t3.medium"
  key_name      = var.key_name

  vpc_security_group_ids = [
    aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id,
    aws_security_group.eks_worker_sg.id
  ]

  user_data = base64encode(local.eks_node_user_data)

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "eks-service-node-instance" }
  }

  lifecycle {
    create_before_destroy = true
  }
}
