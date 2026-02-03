terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
