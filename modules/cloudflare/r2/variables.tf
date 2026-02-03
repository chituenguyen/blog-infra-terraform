variable "account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "buckets" {
  description = "Map of R2 bucket names to their configurations"
  type = map(object({
    # R2 location hint: APAC | EU | NA
    location = optional(string, "APAC")
  }))
}
