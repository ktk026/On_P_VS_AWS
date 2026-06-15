resource "null_resource" "helm_repo_update" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<EOT
      helm repo add aws-load-balancer-controller https://aws.github.io/eks-charts || true
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
      helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
      helm repo add bitnami https://charts.bitnami.com/bitnami || true
      helm repo update
    EOT
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  version    = "4.15.1"

  values = [
    <<EOF
    controller:
      image:
        tag: "v1.11.3"
      service:
        type: LoadBalancer
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
          service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
          service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"

      nodeSelector:
        role: ops

      tolerations:
        - key: "role"
          operator: "Equal"
          value: "ops"
          effect: "NoSchedule"
    EOF
  ]

  depends_on = [aws_eks_addon.vpc_cni, kubernetes_namespace.ingress_nginx]
}




resource "helm_release" "monitoring_exporters" {
  name       = "monitoring-exporters"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "ops"

  values = [
    "${file("${path.module}/values.yaml")}"
  ]

  depends_on = [aws_eks_node_group.ops, aws_eks_addon.vpc_cni, kubernetes_namespace.ops]
  
}



resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.12.1"
  namespace        = "kube-system"
  create_namespace = false
  wait             = true

  set {
    name  = "settings.clusterName"
    value = aws_eks_cluster.eks.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_eks_access_entry.karpenter_node,
    aws_iam_role_policy_attachment.karpenter_controller
  ]
}


resource "helm_release" "event_exporter" {
  name      = "event-exporter"
  chart     = "bitnami/kubernetes-event-exporter"
  version   = "3.6.3"
  namespace = "ops"

  values = [
    <<EOF
image:
  registry: docker.io
  repository: bitnamilegacy/kubernetes-event-exporter
  tag: 1.7.0-debian-12-r46

nodeSelector:
  role: ops

tolerations:
  - key: "role"
    operator: "Equal"
    value: "ops"
    effect: "NoSchedule"
EOF
  ]

  depends_on = [kubernetes_namespace.ops, aws_eks_node_group.ops]
}