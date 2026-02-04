variable "zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "records" {
  description = "Map of DNS records to create"
  type = map(object({
    type    = string
    name    = string
    content = string
    proxied = optional(bool, true)
    ttl     = optional(number, 1) # 1 = auto
  }))
  default = {}
}
