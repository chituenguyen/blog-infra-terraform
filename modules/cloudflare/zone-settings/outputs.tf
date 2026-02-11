output "zone_settings_id" {
  description = "Zone settings override resource ID"
  value       = cloudflare_zone_settings_override.this.id
}

output "page_rule_ids" {
  description = "Page rule IDs"
  value = {
    www_redirect = cloudflare_page_rule.www_redirect.id
  }
}
