resource "aws_eks_cluster" "eks" {
  name                          = var.cluster_name
  role_arn                      = aws_iam_role.cluster_role.arn
  version                       = var.k8s_version
  bootstrap_self_managed_addons = false

  vpc_config {
    subnet_ids = [
      aws_subnet.public_2a.id,
      aws_subnet.public_2c.id
    ]
  }

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = aws_iam_role.auto_mode_node_role.arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_compute_policy,
    aws_iam_role_policy_attachment.eks_block_storage_policy,
    aws_iam_role_policy_attachment.eks_load_balancing_policy,
    aws_iam_role_policy_attachment.eks_networking_policy,
    aws_iam_role_policy_attachment.auto_mode_node_worker_minimal,
    aws_iam_role_policy_attachment.auto_mode_node_ecr_pull_only,
    aws_route_table_association.public_2a,
    aws_route_table_association.public_2c,
  ]
}





resource "aws_eks_access_entry" "k8s_user" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = "arn:aws:iam::367299441871:user/k8s"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "k8s_admin_binding" {
  cluster_name  = aws_eks_cluster.eks.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::367299441871:user/k8s"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.k8s_user]
}

resource "terraform_data" "update_kubeconfig" {
  input = {
    cluster_name = aws_eks_cluster.eks.name
    region       = "ap-northeast-2"
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${self.input.region} --name ${self.input.cluster_name}"
  }

  depends_on = [aws_eks_cluster.eks]
}
