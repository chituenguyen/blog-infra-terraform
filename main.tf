locals {
  # Repos under a user account (not GitHub Organization) cannot use push_allowances/force_push_bypassers.
  # Set true only when owner is an org; then maintainers get direct push + force push.
  is_organization = false

  # Only used when is_organization = true. Format: "/username" or "org/team-slug".
  push_allowances_maintainers = local.is_organization ? ["/chituenguyen"] : []

  # main: require PR + 1 approval; when org, only maintainers can push + force push
  main_protection = {
    enforce_admins        = false
    required_approvals    = 1
    dismiss_stale_reviews = true
    require_status_checks = []
    push_allowances       = local.push_allowances_maintainers
    force_push_bypassers  = local.push_allowances_maintainers
  }
  # dev: lighter; only maintainers can push + force push
  dev_protection = {
    enforce_admins        = false
    required_approvals    = 0
    dismiss_stale_reviews = true
    require_status_checks = []
    push_allowances       = local.push_allowances_maintainers
    force_push_bypassers  = local.push_allowances_maintainers
  }

  # Pattern: k8s/*; only maintainers can push + force push
  k8s_pattern_protection = {
    enforce_admins        = false
    required_approvals    = 0
    dismiss_stale_reviews = true
    require_status_checks = []
    push_allowances       = local.push_allowances_maintainers
    force_push_bypassers  = local.push_allowances_maintainers
  }

  protected_main_and_dev = {
    main    = local.main_protection
    dev     = local.dev_protection
    "k8s/*" = local.k8s_pattern_protection # pattern: any branch starting with k8s/
  }

  # Collaborators applied to all repos (invite + permission)
  common_collaborators = {
    "TueNguyen-Qualgo" = "push"
  }

  repositories = {
    "blog-service-api" = {
      description        = "Blog API service"
      protected_branches = local.protected_main_and_dev
      collaborators      = local.common_collaborators
    }

    "blog-service-ui" = {
      description        = "Blog UI service"
      protected_branches = local.protected_main_and_dev
      collaborators      = local.common_collaborators
    }

    "blog-service-consumer" = {
      description        = "Blog consumer service"
      protected_branches = local.protected_main_and_dev
      collaborators      = local.common_collaborators
    }

    "blog-helm-charts" = {
      description        = "Helm charts for blog services"
      protected_branches = local.protected_main_and_dev
      collaborators      = local.common_collaborators
    }

    "blog-platform-k8s" = {
      description        = "Kubernetes platform configs"
      protected_branches = local.protected_main_and_dev
      collaborators      = local.common_collaborators
    }
  }

  # ---------------------------------------------------------------------------
  # Cloudflare R2 buckets
  # ---------------------------------------------------------------------------
  r2_buckets = {
    "blog-media" = {
      location = "APAC"
    }
  }

  # ---------------------------------------------------------------------------
  # Cloudflare DNS Records
  # ---------------------------------------------------------------------------
  # These records will be created after K3s module to use the Elastic IP
  # Update the domain names below to match your domain
  dns_records = {
    # Root domain
    "root" = {
      type    = "A"
      name    = "@"
      content = "" # Will be set dynamically from K3s Elastic IP
      proxied = true
    }
    # Blog subdomain
    "blog" = {
      type    = "A"
      name    = "blog"
      content = ""
      proxied = true
    }
    # API subdomain
    "api" = {
      type    = "A"
      name    = "api"
      content = ""
      proxied = true
    }
    # Grafana subdomain
    "grafana" = {
      type    = "A"
      name    = "grafana"
      content = ""
      proxied = true
    }
  }

  # ---------------------------------------------------------------------------
  # K3s Clusters
  # ---------------------------------------------------------------------------
  k3s_clusters = {
    "blog-k3s" = {
      instance_type      = "t3.small"
      availability_zone  = "ap-southeast-1a"
      vpc_cidr           = "10.0.0.0/16"
      public_subnet_cidr = "10.0.1.0/24"
      k3s_version        = "stable"
      allowed_ssh_cidrs  = var.allowed_ssh_cidrs
      allowed_api_cidrs  = var.allowed_ssh_cidrs
      expose_http        = true
      expose_https       = true

      # WireGuard VPN
      vpn_enabled = true
      vpn_subnet  = "10.10.0.0/24"
      vpn_port    = 51820
      vpn_clients = {
        "user1" = { ip = "10.10.0.2" }
        "user2" = { ip = "10.10.0.3" }
        "user3" = { ip = "10.10.0.4" }
      }

      tags = {
        Environment = "dev"
        Project     = "blog"
      }
    }
  }
}

module "github_repo" {
  source = "./modules/github-repo"

  repositories = local.repositories
}

module "cloudflare_r2" {
  source = "./modules/cloudflare/r2"

  account_id = var.cloudflare_account_id
  buckets    = local.r2_buckets
}

module "cloudflare_dns" {
  source = "./modules/cloudflare/dns"

  zone_id = var.cloudflare_zone_id
  records = {
    for name, record in local.dns_records : name => {
      type    = record.type
      name    = record.name
      content = module.k3s["blog-k3s"].public_ip
      proxied = record.proxied
    }
  }
}

module "k3s" {
  source   = "./modules/aws/k3s"
  for_each = local.k3s_clusters

  name               = each.key
  instance_type      = each.value.instance_type
  availability_zone  = each.value.availability_zone
  vpc_cidr           = each.value.vpc_cidr
  public_subnet_cidr = each.value.public_subnet_cidr
  ssh_public_key     = var.ssh_public_key
  allowed_ssh_cidrs  = each.value.allowed_ssh_cidrs
  allowed_api_cidrs  = each.value.allowed_api_cidrs
  expose_http        = each.value.expose_http
  expose_https       = each.value.expose_https
  k3s_version        = each.value.k3s_version
  tags               = each.value.tags

  # VPN
  vpn_enabled = each.value.vpn_enabled
  vpn_subnet  = each.value.vpn_subnet
  vpn_port    = each.value.vpn_port
  vpn_clients = each.value.vpn_clients

  # Monitoring
  grafana_admin_password = var.grafana_admin_password
  domain                 = var.domain
}

# ---------------------------------------------------------------------------
# AWS EFS (Persistent Storage)
# ---------------------------------------------------------------------------
module "efs" {
  source = "./modules/aws/efs"

  name                       = "blog-efs"
  vpc_id                     = module.k3s["blog-k3s"].vpc_id
  subnet_id                  = module.k3s["blog-k3s"].subnet_id
  allowed_security_group_ids = [module.k3s["blog-k3s"].security_group_id]
  encrypted                  = true
  performance_mode           = "generalPurpose"
  throughput_mode            = "bursting"

  tags = {
    Environment = "dev"
    Project     = "blog"
  }
}

# ---------------------------------------------------------------------------
# AWS RDS PostgreSQL
# ---------------------------------------------------------------------------
module "rds" {
  source = "./modules/aws/rds"

  name                       = "blog-db"
  vpc_id                     = module.k3s["blog-k3s"].vpc_id
  vpc_cidr                   = "10.0.0.0/16"
  availability_zones         = ["ap-southeast-1a", "ap-southeast-1b"]
  allowed_security_group_ids = [module.k3s["blog-k3s"].security_group_id]
  allowed_cidr_blocks        = module.k3s["blog-k3s"].vpn_subnet != null ? [module.k3s["blog-k3s"].vpn_subnet] : []

  engine          = "postgres"
  engine_version  = "15"
  instance_class  = "db.t3.micro"
  allocated_storage = 20

  database_name           = "blog"
  username                = "blog_admin"
  password                = var.db_password
  backup_retention_period = 7
  skip_final_snapshot     = true

  tags = {
    Environment = "dev"
    Project     = "blog"
  }
}

output "k3s_clusters" {
  description = "K3s cluster connection details"
  value = {
    for name, cluster in module.k3s : name => {
      public_ip              = cluster.public_ip
      private_ip             = cluster.private_ip
      instance_id            = cluster.instance_id
      ssh_command            = cluster.ssh_command
      kubeconfig_command     = cluster.kubeconfig_command
      vpn_enabled            = cluster.vpn_enabled
      vpn_endpoint           = cluster.vpn_endpoint
      vpn_server_ip          = cluster.vpn_server_ip
      vpn_client_config_cmd  = cluster.vpn_client_config_command
    }
  }
}

output "dns_records" {
  description = "Cloudflare DNS records"
  value       = module.cloudflare_dns.records
}

output "efs" {
  description = "EFS storage details"
  value = {
    file_system_id = module.efs.file_system_id
    dns_name       = module.efs.dns_name
    mount_command  = module.efs.mount_command
  }
}

output "rds" {
  description = "RDS database details"
  value = {
    endpoint      = module.rds.endpoint
    address       = module.rds.address
    port          = module.rds.port
    database_name = module.rds.database_name
    username      = module.rds.username
  }
}
