provider "gitlab" {
  base_url = var.gitlab_url
  token    = var.gitlab_token
  # TLS auto-signé en local : désactivé pour le POC
  insecure = true
}
