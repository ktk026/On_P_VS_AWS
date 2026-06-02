resource "helm_release" "nginx_ingress" {
    name             = "ingress-nginx"
    repository       = "https://kubernetes.github.io/ingress-nginx"
    chart            = "ingress-nginx"
    namespace        = "ingress-nginx"
    create_namespace = true
    version          = "4.10.0"

    set {
        name  = "controller.service.type"
        value = "LoadBalancer"
    }
    set {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
        value = "nlb"
    }
}