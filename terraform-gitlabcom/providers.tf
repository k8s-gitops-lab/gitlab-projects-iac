# Pas de base_url (defaut https://gitlab.com) ni insecure : contrairement a
# terraform/providers.tf (instance locale, TLS auto-signe), gitlab.com a un
# certificat public valide.
provider "gitlab" {
  token = var.gitlab_token
}
