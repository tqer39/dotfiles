variable "account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

variable "workers" {
  description = "List of workers to create"
  type = list(object({
    name    = string
    pattern = string
    content = string
  }))
  default = []
}
