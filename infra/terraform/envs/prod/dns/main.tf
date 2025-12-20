module "cloudflare" {
  source = "../../../modules/cloudflare"

  zone_id = var.cloudflare_zone_id

  records = [
    {
      name    = "install"
      type    = "CNAME"
      content = "raw.githubusercontent.com"
      proxied = true
      comment = "dotfiles install script endpoint"
    }
  ]

  redirects = [
    {
      source      = "install.tqer39.dev"
      destination = "https://raw.githubusercontent.com/tqer39/dotfiles/main/install.sh"
      status_code = 302
    }
  ]
}
