output "deploy_role_arn" {
  description = "ARN of the deploy IAM role for GitHub Actions"
  value       = module.deploy_role.role_arn
}

output "deploy_role_name" {
  description = "Name of the deploy IAM role"
  value       = module.deploy_role.role_name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.deploy_role.oidc_provider_arn
}
