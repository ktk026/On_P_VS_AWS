removed {
  from = aws_ecr_repository.services

  lifecycle {
    destroy = false
  }
}


resource "kubernetes_secret" "db_secret" {
  metadata {
    name      = "db-secret"
    namespace = "shoply"
  }

  data = {
    username = var.db_username
    password = var.db_password
  }

  depends_on = [aws_eks_cluster.eks]
  
}
