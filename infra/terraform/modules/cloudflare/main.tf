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

resource "cloudflare_ruleset" "redirects" {
  count = length(var.redirects) > 0 ? 1 : 0

  zone_id = var.zone_id
  name    = "Redirect rules"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  dynamic "rules" {
    for_each = var.redirects
    content {
      action = "redirect"
      action_parameters {
        from_value {
          status_code = rules.value.status_code
          target_url {
            value = rules.value.destination
          }
          preserve_query_string = false
        }
      }
      expression  = "(http.host eq \"${rules.value.source}\")"
      description = "Redirect ${rules.value.source}"
      enabled     = true
    }
  }
}
