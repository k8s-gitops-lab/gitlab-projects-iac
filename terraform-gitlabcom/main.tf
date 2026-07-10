# Migration GitLab self-hosted -> gitlab.com (cf. cockpit/docs/backlog.md,
# section "Migration GitLab self-hosted -> GitLab.com"). Bascule big bang
# decidee le 2026-07-10 : ce module absorbe desormais aussi le CI/CD
# (variables de groupe, bot de push dedie), cf. terraform/main.tf
# (instance locale, decommissionnee) pour le pattern d'origine repris ici.

locals {
  # Meme CA que platform-gitops/argocd/platform/tf-controller/
  # zscaler-ca-configmap.yaml -- certificat public, pas un secret.
  zscaler_ca_pem = <<-EOT
    -----BEGIN CERTIFICATE-----
    MIIE6DCCA9CgAwIBAgIJANu+mC2Jt3uTMA0GCSqGSIb3DQEBCwUAMIGhMQswCQYD
    VQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTERMA8GA1UEBxMIU2FuIEpvc2Ux
    FTATBgNVBAoTDFpzY2FsZXIgSW5jLjEVMBMGA1UECxMMWnNjYWxlciBJbmMuMRgw
    FgYDVQQDEw9ac2NhbGVyIFJvb3QgQ0ExIjAgBgkqhkiG9w0BCQEWE3N1cHBvcnRA
    enNjYWxlci5jb20wIBcNMjUwMjAyMTYzODIwWhgPMjA1MjA2MjAxNjM4MjBaMIGh
    MQswCQYDVQQGEwJVUzETMBEGA1UECBMKQ2FsaWZvcm5pYTERMA8GA1UEBxMIU2Fu
    IEpvc2UxFTATBgNVBAoTDFpzY2FsZXIgSW5jLjEVMBMGA1UECxMMWnNjYWxlciBJ
    bmMuMRgwFgYDVQQDEw9ac2NhbGVyIFJvb3QgQ0ExIjAgBgkqhkiG9w0BCQEWE3N1
    cHBvcnRAenNjYWxlci5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
    AQCpPtJNLFlFOAQUV/p2gdqNJzW+TmObOYzoFa46jTjgSxpNz15URX8eMf/UNbNm
    1yt9OP6eLbTlqkxOUoFbdRhH6XIsdD0WhmINdhcrymgpJXn5ObRWWz/kpvyaSFVW
    q/suBgSa8Rjsc9j6LWcQZkJrjplcI6iEnSYES0H0lWWkMg76c3SFQwBhh1nUplYI
    w1/kn9pNmJKGyis3YDfyJI6F136ZxEziI0veCwu731eEqdGoqgd4fzeVV1+7VcF6
    hDPPlXqADeRtG+EPCgiVMF4xrmXjJF0kB92mRsXOqLBKA12FvFMedhiisPMp+vas
    QUx2wxTQMd14Bl/vXX7UK6e5AgMBAAGjggEdMIIBGTAdBgNVHQ4EFgQUubfdSs3D
    DgyGnV3f7BwEacVOmN8wDwYDVR0TAQH/BAUwAwEB/zCB1gYDVR0jBIHOMIHLgBS5
    t91KzcMODIadXd/sHARpxU6Y36GBp6SBpDCBoTELMAkGA1UEBhMCVVMxEzARBgNV
    BAgTCkNhbGlmb3JuaWExETAPBgNVBAcTCFNhbiBKb3NlMRUwEwYDVQQKEwxac2Nh
    bGVyIEluYy4xFTATBgNVBAsTDFpzY2FsZXIgSW5jLjEYMBYGA1UEAxMPWnNjYWxl
    ciBSb290IENBMSIwIAYJKoZIhvcNAQkBFhNzdXBwb3J0QHpzY2FsZXIuY29tggkA
    276YLYm3e5MwDgYDVR0PAQH/BAQDAgGGMA0GCSqGSIb3DQEBCwUAA4IBAQBZ257u
    6xcDnfq33Dhdi0h/g+5kz5wto+0w1U/y2V3bAfwOzvSiKfrOGEssYNVdv17qSOUC
    jFs/kvCmZnS2ZAr/iAxeD8qkC6Zb5552LRCiV4XHBaeN6Cd+YTJMgVKmBxFrsxlE
    PmauxO1aIwTf3eQmD+n5Yn7MkKClIedkfrwHq4s3ZvyvyplAwjSwyesmEz/5Gdk9
    XdhsfrIlWq8DyJijNGysBOceYOB6jmCijtwFG02ubAfiIMZ/BRC8+O7wjzDgRALz
    OC2+mQytSkKo8K6MskfEdjQGZctKaPISG344PQY/y4zKBf1JNpSfsTBzaI9lj7PK
    m7q2TzMp8s5DuGbK
    -----END CERTIFICATE-----
  EOT
}

resource "gitlab_group" "root" {
  name        = "k8s-gitops-lab"
  path        = "k8s-gitops-lab"
  description = "POC CI/CD GitOps -- groupe racine (migration depuis le GitLab self-hosted local)"
  # Cree manuellement via l'UI (creation de groupe top-level bloquee via API
  # sur ce compte, 403 sans detail malgre can_create_group=true -- probable
  # restriction anti-abus gitlab.com), puis importe dans l'etat Terraform.
  # Public choisi explicitement par l'utilisateur (les groupes locaux sont
  # prives, mais rien ne l'impose ici).
  visibility_level = "public"
}

resource "gitlab_group" "infra" {
  name             = "infra"
  path             = "infra"
  parent_id        = gitlab_group.root.id
  description      = "Ressources infrastructure"
  visibility_level = "private"
}

resource "gitlab_group" "shared_ci" {
  name             = "shared-ci"
  path             = "shared-ci"
  parent_id        = gitlab_group.root.id
  description      = "Templates CI/CD partages, reutilisables par toute app"
  visibility_level = "private"
}

resource "gitlab_group" "hello_groupe" {
  name             = "hello-groupe"
  path             = "hello-groupe"
  parent_id        = gitlab_group.root.id
  description      = "Groupe dedie a l'app helloworld"
  visibility_level = "private"
}

# Projets vides : le contenu est pousse manuellement (git push) juste apres
# l'apply, ce qui *est* la validation du mirroring demandee pour cette
# phase -- pas d'import_url ici.

resource "gitlab_project" "platform_gitops" {
  name             = "platform-gitops"
  path             = "platform-gitops"
  namespace_id     = gitlab_group.infra.id
  description      = "GitOps source de verite"
  visibility_level = "private"
}

resource "gitlab_project" "ci_templates" {
  name             = "ci-templates"
  path             = "ci-templates"
  namespace_id     = gitlab_group.shared_ci.id
  description      = "Templates CI/CD partages"
  visibility_level = "private"
}

resource "gitlab_project" "helloworld" {
  name             = "helloworld"
  path             = "helloworld"
  namespace_id     = gitlab_group.hello_groupe.id
  description      = "Application de demonstration du pattern CI/CD complet"
  visibility_level = "private"
}

resource "gitlab_project" "helloworld_iac" {
  name             = "helloworld-iac"
  path             = "helloworld-iac"
  namespace_id     = gitlab_group.hello_groupe.id
  description      = "IaC helloworld"
  visibility_level = "private"
}

# ── CI/CD : bot de push dedie + variables de groupe ──────────────────────────
# terraform/main.tf (instance locale) utilise un vrai compte utilisateur
# (gitlab_user.ci_push) car un bot de groupe ne peut pas rejoindre un AUTRE
# groupe top-level (restriction GitLab). Ici inutile : hello-groupe est un
# sous-groupe du groupe racine, donc herite nativement de l'acces d'un bot
# cree sur ce dernier. Un vrai gitlab_user est de toute facon impossible sur
# gitlab.com (POST /api/v4/users -> 403, reserve a l'admin d'instance,
# jamais accessible a un compte SaaS standard, verifie le 2026-07-10) :
# gitlab_group_access_token (bot de groupe, pas un utilisateur) est le seul
# mecanisme disponible ici.

resource "gitlab_group_access_token" "ci_push" {
  group        = gitlab_group.root.id
  name         = "ci-push-token"
  access_level = "maintainer"
  expires_at   = "2027-07-10"
  scopes       = ["api", "read_repository", "write_repository"]
}

resource "gitlab_group_variable" "gitlab_push_token" {
  group             = gitlab_group.root.id
  key               = "GITLAB_PUSH_TOKEN"
  value             = gitlab_group_access_token.ci_push.token
  protected         = false
  masked            = true
  environment_scope = "*"
}

resource "gitlab_group_variable" "ghcr_token" {
  group             = gitlab_group.root.id
  key               = "GHCR_TOKEN"
  value             = var.github_token
  protected         = false
  masked            = true
  environment_scope = "*"
}

resource "gitlab_group_variable" "custom_ca_certs" {
  group             = gitlab_group.root.id
  key               = "CUSTOM_CA_CERTS"
  value             = local.zscaler_ca_pem
  protected         = false
  masked            = false
  environment_scope = "*"
}

# deploy.py (ci-templates) construit l'URL de push manifests a partir de ces
# trois variables -- defauts locaux (http/root/hote in-cluster) surcharges
# ici pour gitlab.com (https, PAT via username conventionnel oauth2).
resource "gitlab_group_variable" "internal_gitlab_host" {
  group             = gitlab_group.root.id
  key               = "INTERNAL_GITLAB_HOST"
  value             = "gitlab.com"
  protected         = false
  masked            = false
  environment_scope = "*"
}

resource "gitlab_group_variable" "gitlab_push_scheme" {
  group             = gitlab_group.root.id
  key               = "GITLAB_PUSH_SCHEME"
  value             = "https"
  protected         = false
  masked            = false
  environment_scope = "*"
}

resource "gitlab_group_variable" "gitlab_push_username" {
  group             = gitlab_group.root.id
  key               = "GITLAB_PUSH_USERNAME"
  value             = "oauth2"
  protected         = false
  masked            = false
  environment_scope = "*"
}
