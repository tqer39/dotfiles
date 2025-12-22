resource "cloudflare_dns_record" "this" {
  for_each = { for r in var.records : "${r.type}-${r.name}" => r }

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  content = each.value.content
  ttl     = each.value.ttl
  proxied = each.value.proxied
  comment = each.value.comment
}
