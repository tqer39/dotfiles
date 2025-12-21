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

  rules = [
    for r in var.redirects : {
      action = "redirect"
      action_parameters = {
        from_value = {
          status_code           = r.status_code
          preserve_query_string = false
          target_url = {
            value = r.destination
          }
        }
      }
      expression  = "(http.host eq \"${r.source}\")"
      description = "Redirect ${r.source}"
      enabled     = true
    }
  ]
}
