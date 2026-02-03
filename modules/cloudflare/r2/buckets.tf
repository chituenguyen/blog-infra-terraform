terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "cloudflare_r2_bucket" "this" {
  for_each = var.buckets

  account_id = var.account_id
  name       = each.key
  location   = each.value.location
}
