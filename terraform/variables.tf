variable "gitlab_url" {
  description = "URL de base de l'instance GitLab"
  type        = string
  default     = "http://gitlab.192.168.33.100.nip.io"
}

variable "gitlab_token" {
  description = "Personal access token GitLab (scopes: api, read_repository, write_repository)"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "Personal access token GitHub (scope: repo) pour le mirroring GitLab → GitHub"
  type        = string
  sensitive   = true
}

variable "apps" {
  description = "Applications déclarées dans platform-gitops (généré par la CI depuis apps.auto.tfvars.json, ne pas éditer à la main)"
  type = list(object({
    name             = string
    group            = string
    description      = optional(string, "")
    importFromGithub = optional(bool, false)
  }))
  default = []
}
