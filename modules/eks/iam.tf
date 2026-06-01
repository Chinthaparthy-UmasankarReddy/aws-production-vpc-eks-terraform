# OIDC Provider for IRSA
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub" # <-- Fixed: Uses standard pre-formatted output
      values   = ["system:serviceaccount:default:jiomart-app-sa"]
    }

    principals {
      identifiers = [module.eks.oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "jiomart_app_role" {
  name               = "${var.cluster_name}-app-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}
