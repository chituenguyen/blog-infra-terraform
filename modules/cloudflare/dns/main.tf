terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "cloudflare_record" "this" {
  for_each = var.records

  zone_id = var.zone_id
  type    = each.value.type
  name    = each.value.name
  content = each.value.content
  proxied = each.value.proxied
  ttl     = each.value.proxied ? 1 : each.value.ttl
}
