variable "github_owner" {
  description = "chituenguyen"
  type        = string
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}