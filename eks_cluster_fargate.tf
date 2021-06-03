resource "aws_eks_cluster" "elk" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.elk.arn

  vpc_config {
    subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.elk-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.elk-AmazonEKSVPCResourceController,
  ]

  tags = {
    COMPONENT_NAME = var.eks_cluster_name
  }
}

output "endpoint" {
  value = aws_eks_cluster.elk.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.elk.certificate_authority[0].data
}

# Fargate

resource "aws_eks_fargate_profile" "elk" {
  cluster_name           = aws_eks_cluster.elk.name
  fargate_profile_name   = "elk_profile"
  pod_execution_role_arn = aws_iam_role.fargate_profile.arn
  subnet_ids             = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

  selector {
    namespace = "default"
  }
  selector {
    namespace = "cert-manager"
  }

  selector {
    namespace = "kube-system"
  }
  tags = {
    COMPONENT_NAME = var.eks_cluster_name
  }
}

# IAM Role

resource "aws_iam_role" "elk" {
  name = "eks-cluster-${var.eks_cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags = {
    COMPONENT_NAME = var.eks_cluster_name
  }
}

resource "aws_iam_role_policy_attachment" "elk-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.elk.name
}

resource "aws_iam_role_policy_attachment" "elk-tag-policy" {
  policy_arn = aws_iam_policy.policy.arn 
  role       = aws_iam_role.elk.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "elk-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.elk.name
}

# IAM role for service account

data "tls_certificate" "elk" {
  url = aws_eks_cluster.elk.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "elk" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.elk.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.elk.identity[0].oidc[0].issuer
  tags = {
    COMPONENT_NAME = var.eks_cluster_name
  }
}

data "aws_iam_policy_document" "elk_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.elk.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.elk.arn]
      type        = "Federated"
    }
  }
}

# resource "aws_iam_role" "elk" {
#   assume_role_policy = data.aws_iam_policy_document.elk_assume_role_policy.json
#   name               = "elk"
# }

# IAM role for fargate profile

resource "aws_iam_role" "fargate_profile" {
  name = "eks-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  inline_policy {
    name = "logging_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["log:*", "ec2:*", "iam:*", "elasticloadbalancing:*", "cognito-idp:*", "acm:*", ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
  tags = {
    COMPONENT_NAME = var.eks_cluster_name
  }
}

# ALB controller iam policy
resource "aws_iam_policy" "policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${var.eks_cluster_name}"
  path        = "/"
  description = "AWSLoadBalancerControllerIAMPolicy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["log:*", "ec2:*", "iam:*", "elasticloadbalancing:*", "cognito-idp:*", "acm:*", "waf:*", "wafv2:*", "waf-regional:*", "shield:*", "tag:*"]

        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_profile.name
}
