terraform {
  required_version = "= 1.14.3"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    key     = "dotfiles/infra/terraform/envs/prod/dns.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}
