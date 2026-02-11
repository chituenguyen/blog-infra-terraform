terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "cloudflare_zone_settings_override" "this" {
  zone_id = var.zone_id

  settings {
    ssl                      = "full"
    min_tls_version          = "1.2"
    tls_1_3                  = "on"
    always_use_https         = "on"
    automatic_https_rewrites = "on"

    security_header {
      enabled            = true
      max_age            = 31536000
      include_subdomains = true
      preload            = false
      nosniff            = true
    }
  }
}

resource "cloudflare_page_rule" "www_redirect" {
  zone_id  = var.zone_id
  target   = "www.${var.domain}/*"
  priority = 1
  status   = "active"

  actions {
    forwarding_url {
      url         = "https://${var.domain}/$1"
      status_code = 301
    }
  }
}
