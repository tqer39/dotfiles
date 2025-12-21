output "dns_records" {
  description = "Created DNS records"
  value = {
    for k, v in cloudflare_dns_record.this : k => {
      name    = v.name
      type    = v.type
      content = v.content
    }
  }
}
