# Worker definition
resource "cloudflare_worker" "this" {
  for_each = { for w in var.workers : w.name => w }

  account_id = var.account_id
  name       = each.value.name
}

# Worker version with code
resource "cloudflare_worker_version" "this" {
  for_each = { for w in var.workers : w.name => w }

  account_id         = var.account_id
  worker_id          = cloudflare_worker.this[each.key].id
  main_module        = "index.mjs"
  compatibility_date = "2024-01-01"

  modules = [{
    name           = "index.mjs"
    content_type   = "application/javascript+module"
    content_base64 = base64encode(each.value.content)
  }]
}

# Deploy the worker version
resource "cloudflare_workers_deployment" "this" {
  for_each = { for w in var.workers : w.name => w }

  account_id  = var.account_id
  script_name = cloudflare_worker.this[each.key].name
  strategy    = "percentage"

  versions = [{
    version_id = cloudflare_worker_version.this[each.key].id
    percentage = 100
  }]
}

# Route to trigger the worker
resource "cloudflare_workers_route" "this" {
  for_each = { for w in var.workers : w.name => w }

  zone_id = var.zone_id
  pattern = each.value.pattern
  script  = cloudflare_worker.this[each.key].name

  depends_on = [cloudflare_workers_deployment.this]
}
