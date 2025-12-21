# 共通設定の読み込み
locals {
  config         = yamldecode(file("../../config.yml"))
  aws_account_id = local.config.aws.account_id
  aws_env_name   = local.config.aws.env_name
  organization   = local.config.project.organization
  repository     = local.config.project.repository
  app_env_name   = local.config.environments.prod.name
}

module "deploy_role" {
  source = "../../../modules/deploy-role"

  aws_account_id = local.aws_account_id
  aws_env_name   = local.aws_env_name
  organization   = local.organization
  repository     = local.repository
  app_env_name   = local.app_env_name
}
