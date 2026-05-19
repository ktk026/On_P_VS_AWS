resource "aws_launch_template" "eks_nodes_template" {
  name_prefix            = "eks-node-template-"
  image_id               = data.aws_ami.ubuntu_eks.id
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.eks_worker_sg.id]

  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -ex
    /etc/eks/bootstrap.sh \
      --b64-cluster-ca "${aws_eks_cluster.eks.certificate_authority[0].data}" \
       --apiserver-endpoint "${aws_eks_cluster.eks.endpoint}" \
      "${var.cluster_name}"
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "eks-node-instance" }
  }

  lifecycle {
    create_before_destroy = true
  }
}
