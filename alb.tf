data "aws_iam_policy_document" "elk_alb_sa" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      identifiers = [aws_iam_openid_connect_provider.elk.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "elk_alb_sc" {
  name = "eks-alb-sa-${var.eks_cluster_name}"

  assume_role_policy = data.aws_iam_policy_document.elk_alb_sa.json

  inline_policy {
    name = "elk_alb_sc_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["log:*", "ec2:*", "iam:*", "elasticloadbalancing:*", "cognito-idp:*", "acm:*", "elasticfilesystem:*", "wafv2:*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}
