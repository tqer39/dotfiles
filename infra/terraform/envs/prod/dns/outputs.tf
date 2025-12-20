output "dns_records" {
  description = "Created DNS records"
  value       = module.cloudflare.dns_records
}
