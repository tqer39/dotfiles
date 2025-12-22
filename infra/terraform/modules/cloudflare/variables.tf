variable "zone_id" {
  description = "CloudFlare Zone ID"
  type        = string
  sensitive   = true
}

variable "records" {
  description = "List of DNS records to create"
  type = list(object({
    name    = string
    type    = string
    content = string
    ttl     = optional(number, 1)
    proxied = optional(bool, false)
    comment = optional(string, "")
  }))
  default = []
}
