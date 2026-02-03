# Repositories
resource "github_repository" "this" {
  for_each = var.repositories

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility

  has_issues   = each.value.has_issues
  has_wiki     = each.value.has_wiki
  has_projects = each.value.has_projects

  delete_branch_on_merge = each.value.delete_branch_on_merge

  auto_init = true
}

# Branch Protection (multiple branches per repo: main, dev, ...)
resource "github_branch_protection" "this" {
  for_each = merge([
    for repo_name, repo in var.repositories : {
      for branch, config in repo.protected_branches :
      "${repo_name}:${branch}" => {
        repo_name = repo_name
        branch    = branch
        config    = config
      }
    }
  ]...)

  repository_id = github_repository.this[each.value.repo_name].node_id
  pattern       = each.value.branch

  # User/team restrictions (push_allowances, force_push_bypassers) only allowed for Organization repos.
  # When empty we omit so personal repos don't get "Only organization repositories can have users and team restrictions".
  allows_force_pushes  = length(each.value.config.force_push_bypassers) > 0 ? false : null
  force_push_bypassers = length(each.value.config.force_push_bypassers) > 0 ? each.value.config.force_push_bypassers : null

  enforce_admins = each.value.config.enforce_admins

  required_pull_request_reviews {
    required_approving_review_count = each.value.config.required_approvals
    dismiss_stale_reviews            = each.value.config.dismiss_stale_reviews
  }

  dynamic "required_status_checks" {
    for_each = length(each.value.config.require_status_checks) > 0 ? [1] : []
    content {
      strict   = true
      contexts = each.value.config.require_status_checks
    }
  }

  # Only maintainers (push_allowances) can push directly; everyone else must use PR
  dynamic "restrict_pushes" {
    for_each = length(each.value.config.push_allowances) > 0 ? [1] : []
    content {
      push_allowances = each.value.config.push_allowances
    }
  }
}

# Collaborators
resource "github_repository_collaborator" "this" {
  for_each = merge([
    for repo_name, repo in var.repositories : {
      for username, permission in repo.collaborators :
      "${repo_name}:${username}" => {
        repository = repo_name
        username   = username
        permission = permission
      }
    }
  ]...)

  repository = github_repository.this[each.value.repository].name
  username   = each.value.username
  permission = each.value.permission
}
