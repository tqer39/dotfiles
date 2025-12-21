# 共通設定の読み込み
locals {
  config       = yamldecode(file("../../config.yml"))
  domain       = local.config.project.domain
  organization = local.config.project.organization
  repository   = local.config.project.repository
}

module "cloudflare" {
  source = "../../../modules/cloudflare"

  zone_id = var.cloudflare_zone_id

  records = [
    {
      name    = "install"
      type    = "CNAME"
      content = "raw.githubusercontent.com"
      proxied = true
      comment = "${local.repository} install script endpoint"
    }
  ]

  redirects = [
    {
      source      = "install.${local.domain}"
      destination = "https://raw.githubusercontent.com/${local.organization}/${local.repository}/main/install.sh"
      status_code = 302
    }
  ]
}
