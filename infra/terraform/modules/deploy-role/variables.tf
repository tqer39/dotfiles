variable "aws_account_id" {
  type        = string
  description = "(Required) AWS account ID"
}

variable "aws_env_name" {
  type        = string
  description = "(Required) AWS Environment name"
}

variable "app_env_name" {
  type        = string
  description = "(Required) Application environment name"
}

variable "organization" {
  type        = string
  description = "(Required) GitHub organization name"
}

variable "repository" {
  type        = string
  description = "(Required) GitHub repository name"
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Tags to apply to resources"
  default     = {}
}
