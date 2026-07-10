variable "gitlab_token" {
  description = "Personal access token gitlab.com (scopes: api, read_repository, write_repository)"
  type        = string
  sensitive   = true
}
