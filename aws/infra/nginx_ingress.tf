resource "kubernetes_service_v1" "nginx_service" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.shoply.metadata[0].name
  }

  spec {
    selector = {
      app = "frontend"
    }

    type = "ClusterIP"

    port {
      port        = 80
      target_port = 80
    }
  }

  depends_on = [helm_release.ingress_nginx]
}