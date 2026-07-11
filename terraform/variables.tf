variable "gitlab_token" {
  description = "Personal access token gitlab.com (scopes: api, read_repository, write_repository)"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "Personal access token GitHub (scope: repo), expose en CI/CD var GHCR_TOKEN et pour import_url des projets importes depuis GitHub"
  type        = string
  sensitive   = true
}

variable "apps" {
  description = "Applications declarees dans platform-gitops (generee par la CI depuis apps.auto.tfvars.json, ne pas editer a la main)"
  type = list(object({
    name             = string
    group            = string
    description      = optional(string, "")
    importFromGithub = optional(bool, false)
  }))
  default = []
}
