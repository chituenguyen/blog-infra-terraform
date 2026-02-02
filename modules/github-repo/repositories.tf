resource "github_repository" "microservices" {
  for_each = toset(var.microservices)

  name       = each.value
  visibility = "public"

  has_issues = true
}
