locals {
  aws_load_balancer_controller_version = "v3.4.0"
  eks_oidc_provider_url                = replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")
}

data "http" "load_balancer_controller_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${local.aws_load_balancer_controller_version}/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "load_balancer_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.load_balancer_controller_iam_policy.response_body
}

resource "aws_iam_role" "load_balancer_controller" {
  name = "AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.eks_oidc_provider_url}:aud" = "sts.amazonaws.com"
            "${local.eks_oidc_provider_url}:sub" = "system:serviceaccount:kube-system:load-balancer-controller"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "load_balancer_controller" {
  role       = aws_iam_role.load_balancer_controller.name
  policy_arn = aws_iam_policy.load_balancer_controller.arn
}

resource "kubernetes_service_account_v1" "load_balancer_controller" {
  metadata {
    name      = "load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.load_balancer_controller.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.load_balancer_controller
  ]
}