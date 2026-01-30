terraform {
  required_version = "1.14.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Bootstrap は初回ローカル実行後、S3 backend に移行
  backend "s3" {
    bucket  = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
    key     = "dotfiles/infra/terraform/envs/prod/bootstrap.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}
