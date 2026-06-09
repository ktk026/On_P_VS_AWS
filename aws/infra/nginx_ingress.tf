resource "kubernetes_service_v1" "nginx_service" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.accommodation.metadata[0].name

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"   = "external"
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-subnets" = join(",", [
        aws_subnet.public_2a.id,
        aws_subnet.public_2c.id
      ])
      "service.beta.kubernetes.io/aws-load-balancer-security-groups" = aws_security_group.load_balancer_sg.id
      "service.beta.kubernetes.io/aws-load-balancer-manage-backend-security-group-rules" = "true"
    }
  }

  spec {
    selector = {
      app = "frontend"
    }

    type = "LoadBalancer"

    port {
      port        = 80
      target_port = 80
    }
  }

  depends_on = [helm_release.load_balancer_controller]

}