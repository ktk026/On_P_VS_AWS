resource "kubectl_manifest" "karpenter_ec2nodeclass" {
  yaml_body = templatefile(
    "${path.module}/karpenter/ec2nodeclass.yaml",
    {
      CLUSTER_NAME   = var.cluster_name
      AMI_ID         = data.aws_ami.ubuntu_eks.id
      NODE_ROLE_NAME = aws_iam_role.karpenter_node.name
    }
  )

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_nodepool_api" {
  yaml_body = file("${path.module}/karpenter/api-nodepool.yaml")

  depends_on = [
    kubectl_manifest.karpenter_ec2nodeclass
  ]
}

resource "kubectl_manifest" "karpenter_nodepool_service" {
  yaml_body = file("${path.module}/karpenter/service-nodepool.yaml")

  depends_on = [
    kubectl_manifest.karpenter_ec2nodeclass
  ]
}