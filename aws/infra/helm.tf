resource "null_resource" "helm_repo_update" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<EOT
      helm repo add aws-load-balancer-controller https://aws.github.io/eks-charts || true
      helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
      helm repo update
    EOT
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  version    = "5.7.1"

  values = [
    <<EOF
    controller:
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

  depends_on = [aws_eks_node_group.ops, kubernetes_namespace.ingress_nginx]
}



resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.1"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  set {
    name  = "args[1]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }

  depends_on = [null_resource.helm_repo_update, kubernetes_namespace.ops, aws_eks_node_group.api_node_group, aws_eks_node_group.service_node_group]
}



resource "helm_release" "monitoring_exporters" {
  name       = "monitoring-exporters"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "ops"

  values = [
    "${file("${path.module}/values.yaml")}"
  ]

  depends_on = [kubernetes_namespace.ops, null_resource.helm_repo_update, aws_eks_node_group.ops]
  
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