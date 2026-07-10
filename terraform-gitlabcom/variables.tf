variable "gitlab_token" {
  description = "Personal access token gitlab.com (scopes: api, read_repository, write_repository)"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "Personal access token GitHub (scope: repo), expose en CI/CD var GHCR_TOKEN pour le push GHCR"
  type        = string
  sensitive   = true
}
