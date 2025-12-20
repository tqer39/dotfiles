variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_env_name" {
  description = "AWS environment name (e.g., portfolio)"
  type        = string
}

variable "organization" {
  description = "GitHub organization name"
  type        = string
}

variable "repository" {
  description = "GitHub repository name"
  type        = string
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "create_oidc_provider" {
  description = "Whether to create the GitHub OIDC provider"
  type        = bool
  default     = true
}

variable "additional_policies" {
  description = "Additional IAM policies to attach to the role"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
