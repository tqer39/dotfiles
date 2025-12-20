locals {
  aws_account_id = "072693953877"
  aws_env_name   = "portfolio"
  organization   = "tqer39"
  repository     = "dotfiles"
  state_bucket   = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
}

module "deploy_role" {
  source = "../../../modules/deploy-role"

  aws_account_id       = local.aws_account_id
  aws_env_name         = local.aws_env_name
  organization         = local.organization
  repository           = local.repository
  state_bucket         = local.state_bucket
  create_oidc_provider = true

  tags = {
    Project   = "dotfiles"
    ManagedBy = "terraform"
  }
}
