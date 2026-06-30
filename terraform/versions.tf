terraform {
  required_version = ">= 1.5.0"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
  }
  backend "kubernetes" {
    secret_suffix     = "gitlab-projects-iac"
    namespace         = "flux-system"
    in_cluster_config = true
  }
}
