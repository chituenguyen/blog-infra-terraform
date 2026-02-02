locals {
  microservices = [
    "blog-service-api",
    "blog-service-ui",
    "blog-service-consumer",
    "blog-helm-charts",
    "blog-platform-k8s"
  ]
}

module "github_repo" {
  source = "./modules/github-repo"

  microservices = local.microservices
}
