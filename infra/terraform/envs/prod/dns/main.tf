# 共通設定の読み込み
locals {
  config       = yamldecode(file("../../config.yml"))
  domain       = local.config.project.domain
  organization = local.config.project.organization
  repository   = local.config.project.repository

  github_raw_base_url = "https://raw.githubusercontent.com/${local.organization}/${local.repository}/main"
}

module "cloudflare" {
  source = "../../../modules/cloudflare"

  zone_id = var.cloudflare_zone_id

  records = [
    {
      name    = "install"
      type    = "A"
      content = "192.0.2.1" # Dummy IP for Workers route
      proxied = true
      comment = "${local.repository} install script endpoint (Workers)"
    }
  ]
}

module "workers" {
  source = "../../../modules/workers"

  account_id = var.cloudflare_account_id
  zone_id    = var.cloudflare_zone_id

  workers = [
    {
      name    = "dotfiles-install-redirect"
      pattern = "install.${local.domain}/*"
      content = <<-JS
        export default {
          async fetch(request) {
            const url = new URL(request.url);
            const path = url.pathname;

            let targetUrl;
            if (path === '/windows' || path === '/windows/') {
              targetUrl = '${local.github_raw_base_url}/install.ps1';
            } else {
              targetUrl = '${local.github_raw_base_url}/install.sh';
            }

            const response = await fetch(targetUrl);
            const body = await response.text();

            return new Response(body, {
              headers: {
                'Content-Type': 'text/plain; charset=utf-8',
                'Cache-Control': 'public, max-age=300',
              },
            });
          }
        }
      JS
    }
  ]
}
