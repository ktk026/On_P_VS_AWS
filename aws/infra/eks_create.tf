resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids = [
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




resource "aws_eks_node_group" "api_node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "api-node-group"
  node_role_arn   = aws_iam_role.worker_role.arn
  subnet_ids      = [aws_subnet.public_2a.id]

  capacity_type = "ON_DEMAND"

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  labels = {
    role = "api"
  }

  launch_template {
    id      = aws_launch_template.eks_api_nodes_template.id
    version = aws_launch_template.eks_api_nodes_template.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_policy,
    aws_iam_role_policy_attachment.worker_cni,
    aws_iam_role_policy_attachment.worker_ecr,
    aws_iam_role_policy_attachment.worker_cloudwatch_agent,
  ]
}

resource "aws_eks_node_group" "service_node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "service-node-group"
  node_role_arn   = aws_iam_role.worker_role.arn
  subnet_ids      = [aws_subnet.public_2a.id]

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }

  capacity_type = "ON_DEMAND"

  labels = {
    role = "service"
  }

  launch_template {
    id      = aws_launch_template.eks_service_nodes_template.id
    version = aws_launch_template.eks_service_nodes_template.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.worker_policy,
    aws_iam_role_policy_attachment.worker_cni,
    aws_iam_role_policy_attachment.worker_ecr,
    aws_iam_role_policy_attachment.worker_cloudwatch_agent,
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
