provider "github" {
  owner = var.github_owner
  token = var.github_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# -----------------------------------------------------------------------------
# AWS Providers - Tách theo chức năng
# -----------------------------------------------------------------------------

# Default provider (dùng cho resources không chỉ định provider)
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "blog-infra"
    }
  }
}

# Compute provider (EC2, K3s, VPC)
provider "aws" {
  alias      = "compute"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "blog-infra"
      Component = "compute"
    }
  }
}

# Storage provider (EFS, S3)
provider "aws" {
  alias      = "storage"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "blog-infra"
      Component = "storage"
    }
  }
}

# Database provider (RDS)
provider "aws" {
  alias      = "database"
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = "blog-infra"
      Component = "database"
    }
  }
}
