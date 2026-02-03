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
