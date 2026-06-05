removed {
  from = aws_ecr_repository.services

  lifecycle {
    destroy = false
  }
}



resource "kubernetes_namespace" "accommodation" {
  metadata {
    name = "accommodation"
  }
}

resource "kubernetes_secret" "db_secret" {
  metadata {
    name      = "db-secret"
    namespace = "accommodation"
  }

  data = {
    username = var.db_username
    password = var.db_password
  }
}
