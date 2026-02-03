output "repositories" {
  description = "Created repositories"
  value = {
    for name, repo in github_repository.this : name => {
      html_url  = repo.html_url
      ssh_url   = repo.ssh_clone_url
      https_url = repo.http_clone_url
    }
  }
}
