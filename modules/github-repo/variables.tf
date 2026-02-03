variable "repositories" {
  description = "Map of repositories with their configurations"
  type = map(object({
    description        = optional(string, "")
    visibility         = optional(string, "public")
    has_issues         = optional(bool, true)
    has_wiki           = optional(bool, false)
    has_projects       = optional(bool, false)
    delete_branch_on_merge = optional(bool, true)

    # Branch protection: map of branch pattern -> config (e.g. "main" = {...}, "dev" = {...})
    protected_branches = optional(map(object({
      enforce_admins        = optional(bool, false)
      required_approvals    = optional(number, 0)
      dismiss_stale_reviews = optional(bool, true)
      require_status_checks = optional(list(string), [])
      # Only these actors can push directly; others must use PR. Format: "/username" or "org/team-slug"
      push_allowances       = optional(list(string), [])
      # Actors allowed to force push (e.g. maintainers). Same format as push_allowances.
      force_push_bypassers  = optional(list(string), [])
    })), {})

    # Collaborators
    collaborators = optional(map(string), {})  # username = permission (pull, push, admin)
  }))
}
