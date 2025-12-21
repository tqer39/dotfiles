data "aws_iam_policy" "deploy_allow_specifics" {
  name = "deploy-allow-specifics"
}

data "aws_iam_policy" "deploy_deny_specifics" {
  name = "deploy-deny-specifics"
}

resource "aws_iam_role" "this" {
  name = "${var.aws_env_name}-${var.repository}-terraform-deploy-${var.app_env_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.organization}/${var.repository}:*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachments_exclusive" "this" {
  role_name = aws_iam_role.this.name
  policy_arns = [
    data.aws_iam_policy.deploy_allow_specifics.arn,
    data.aws_iam_policy.deploy_deny_specifics.arn,
  ]
}
