resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn
  version  = "1.32"

  vpc_config {
    subnet_ids = [
      aws_subnet.private_2a.id,
      aws_subnet.private_2c.id,
      aws_subnet.public_2a.id,
      aws_subnet.public_2c.id
    ]
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}




resource "aws_eks_node_group" "app_node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "app-node-group"
  node_role_arn   = aws_iam_role.worker_role.arn
  subnet_ids      = [aws_subnet.private_2a.id, aws_subnet.private_2c.id]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 2
  }

  ami_type      = "CUSTOM"
  capacity_type = "ON_DEMAND"


  launch_template {
    id      = aws_launch_template.eks_nodes_template.id
    version = "$Latest"
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_policy,
    aws_iam_role_policy_attachment.worker_cni,
    aws_iam_role_policy_attachment.worker_ecr,
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


resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}
