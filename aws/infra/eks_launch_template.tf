resource "aws_launch_template" "eks_api_nodes_template" {
  name_prefix            = "eks-api-node-"
  image_id               = data.aws_ami.ubuntu_eks.id
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.eks_worker_sg.id]

  key_name = "key"

  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -ex
    /etc/eks/bootstrap.sh "${var.cluster_name}" \
      --b64-cluster-ca "${aws_eks_cluster.eks.certificate_authority[0].data}" \
      --apiserver-endpoint "${aws_eks_cluster.eks.endpoint}"
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "eks-api-node-instance" }
  }

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_launch_template" "eks_service_nodes_template" {
  name_prefix            = "eks-service-node-"
  image_id               = data.aws_ami.ubuntu_eks.id
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.eks_worker_sg.id]

  key_name = "key"

  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -ex
    /etc/eks/bootstrap.sh "${var.cluster_name}" \
      --b64-cluster-ca "${aws_eks_cluster.eks.certificate_authority[0].data}" \
      --apiserver-endpoint "${aws_eks_cluster.eks.endpoint}"
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "eks-service-node-instance" }
  }

  lifecycle {
    create_before_destroy = true
  }
}
