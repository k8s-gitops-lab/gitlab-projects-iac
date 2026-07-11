# Module gitlab.com (migration depuis l'instance self-hosted, decommissionnee
# le 2026-07-10 -- cf. cockpit/docs/backlog.md, section "Migration GitLab
# self-hosted -> GitLab.com"). Contrairement a l'instance locale, gitlab.com
# refuse gitlab_application_settings et gitlab_user/group_access_token a un
# compte non-admin (403 verifies en direct) : pas de bot dedie, le PAT
# proprietaire (var.gitlab_token) est reutilise tel quel comme
# GITLAB_PUSH_TOKEN.

locals {
  github_base = "https://github.com/k8s-gitops-lab"

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

  # Une entrée par projet GitLab applicatif : le repo de code (<name>) et son
  # repo manifests (<name>-iac), dérivés de var.apps (généré depuis
  # platform-gitops/argocd/apps/*.yaml — cf. toolbox/scripts/render-gitlab-projects.py).
  # `group` porte le groupe GitLab dédié à l'app (ex. "hello-groupe" pour
  # helloworld), déclaré explicitement dans le descriptor de l'app.
  app_projects = merge([
    for app in var.apps : {
      "${app.name}" = {
        name               = app.name
        group              = app.group
        description        = app.description != "" ? app.description : "Application ${app.name}${app.importFromGithub ? " — importé depuis GitHub" : ""}"
        import_from_github = app.importFromGithub
      }
      "${app.name}-iac" = {
        name               = "${app.name}-iac"
        group              = app.group
        description        = "IaC ${app.name}${app.description != "" ? " — ${app.description}" : ""}${app.importFromGithub ? " — importé depuis GitHub" : ""}"
        import_from_github = app.importFromGithub
      }
    }
  ]...)

  # Un groupe GitLab dédié par app (clé = nom du groupe, valeur = nom de
  # l'app propriétaire, pour les descriptions), sous-groupe du groupe racine.
  app_groups = { for app in var.apps : app.group => app.name }
}

# ── Groupe racine ──────────────────────────────────────────────────────────

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
  # Sans ceci, les jobs sans tag (cas de tous nos pipelines) sont eligibles
  # aussi bien a notre runner group_type qu'aux runners SaaS partages -- et
  # gitlab.com a systematiquement prefere le partage lors de la validation
  # du 2026-07-10, produisant des images amd64 sur un cluster arm64
  # (exec format error). unoverridable pour qu'aucun sous-groupe/projet ne
  # puisse le reactiver par erreur -- cf. cockpit/docs/backlog.md.
  shared_runners_setting = "disabled_and_unoverridable"
}

# ── Groupe dédié aux ressources gérées par Terraform ─────────────────────────

resource "gitlab_group" "infra" {
  name             = "infra"
  path             = "infra"
  parent_id        = gitlab_group.root.id
  description      = "Ressources infrastructure gérées par Terraform via tf-controller"
  visibility_level = "private"
}

# ── Groupe dédié aux templates CI/CD partagés ─────────────────────────────────
# ci-templates n'a pas de pipeline propre (pas de .gitlab-ci.yml à la racine,
# seulement le fichier gitlab-ci.yml consommé via `include:` par les apps),
# donc aucune variable de groupe n'a besoin d'y être dupliquée.

resource "gitlab_group" "shared_ci" {
  name             = "shared-ci"
  path             = "shared-ci"
  parent_id        = gitlab_group.root.id
  description      = "Templates CI/CD partagés, réutilisables par toute app"
  visibility_level = "private"
}

# ── Groupes dédiés par app ─────────────────────────────────────────────────────
# Un sous-groupe du groupe racine par app (ex. "hello-groupe" pour
# helloworld) : chaque app est isolée dans son propre groupe, à la fois pour
# son repo de code et son repo manifests, mais hérite des variables CI/CD du
# groupe racine (GHCR_TOKEN, CUSTOM_CA_CERTS, GITLAB_PUSH_TOKEN, ...).

resource "gitlab_group" "app" {
  for_each = local.app_groups

  name             = each.key
  path             = each.key
  parent_id        = gitlab_group.root.id
  description      = "Groupe dédié à l'app ${each.value}"
  visibility_level = "private"
}

# ── Variables CI/CD du groupe racine ─────────────────────────────────────────
# Déclarées une seule fois ici : héritées par tous les sous-groupes
# (infra, shared-ci, groupes d'app), contrairement aux groupes top-level
# indépendants de l'ancienne instance locale.

resource "gitlab_group_variable" "gitlab_push_token" {
  group             = gitlab_group.root.id
  key               = "GITLAB_PUSH_TOKEN"
  value             = var.gitlab_token
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

# .fetch-scripts (ci-templates) clone shared-ci/ci-templates depuis
# INTERNAL_GITLAB_HOST -- chemin relatif suppose des groupes top-level
# (vrai en local), faux sur gitlab.com ou shared-ci est un sous-groupe de
# k8s-gitops-lab. Sans cette surcharge, la resolution du chemin de clone
# echoue silencieusement sur un mauvais chemin.
resource "gitlab_group_variable" "ci_templates_project_path" {
  group             = gitlab_group.root.id
  key               = "CI_TEMPLATES_PROJECT_PATH"
  value             = "k8s-gitops-lab/shared-ci/ci-templates"
  protected         = false
  masked            = false
  environment_scope = "*"
}

# Reutilise le token GitHub deja fourni au Terraform (var.github_token) pour
# l'exposer au pipeline GitLab CI de platform-gitops : clone de
# platform-bootstrap/toolbox (prives) et push des commits generes vers les
# depots GitHub canoniques (onboard-apps, cf. platform-gitops/.gitlab-ci.yml).
# Limite au groupe infra (platform-gitops), pas besoin ailleurs.
resource "gitlab_group_variable" "github_token_ci" {
  group             = gitlab_group.infra.id
  key               = "GITHUB_TOKEN"
  value             = var.github_token
  protected         = false
  masked            = true
  environment_scope = "*"
}

# ── Projets applicatifs ────────────────────────────────────────────────────────
# Une entrée par app déclarée dans platform-gitops (cf. locals.app_projects).
# import_url n'est renseigné que pour les apps historiques (importFromGithub:
# true, ex. helloworld) dont le repo GitHub préexiste ; les nouvelles apps sont
# créées vides, le code n'existant pas encore ailleurs.

resource "gitlab_project" "app" {
  for_each = local.app_projects

  name             = each.value.name
  path             = each.value.name
  namespace_id     = gitlab_group.app[each.value.group].id
  description      = each.value.description
  visibility_level = "private"
  import_url       = each.value.import_from_github ? "${local.github_base}/${each.value.name}.git" : null

  merge_method                     = "merge"
  squash_option                    = "default_off"
  remove_source_branch_after_merge = true
}

resource "gitlab_branch_protection" "app_main" {
  for_each = local.app_projects

  project            = gitlab_project.app[each.key].id
  branch             = "main"
  push_access_level  = "maintainer"
  merge_access_level = "developer"
  allow_force_push   = false
}

resource "gitlab_project" "ci_templates" {
  name             = "ci-templates"
  path             = "ci-templates"
  namespace_id     = gitlab_group.shared_ci.id
  description      = "Templates CI/CD partagés — importé depuis GitHub"
  visibility_level = "private"
  import_url       = "${local.github_base}/ci-templates.git"

  merge_method                     = "merge"
  squash_option                    = "default_off"
  remove_source_branch_after_merge = true
}

resource "gitlab_branch_protection" "ci_templates_main" {
  project            = gitlab_project.ci_templates.id
  branch             = "main"
  push_access_level  = "maintainer"
  merge_access_level = "developer"
  allow_force_push   = false
}

# ── platform-gitops ────────────────────────────────────────────────────────────
# Les PR/MR se font sur ce projet GitLab (pas sur GitHub) : import initial
# depuis GitHub puis développement normal sur GitLab. Le merge d'une MR
# déclenche directement le pipeline `.gitlab-ci.yml`. Pas de mirror push
# automatique vers GitHub (dette assumee, cf. cockpit/docs/backlog.md et
# CLAUDE.md -- le mirror local force-ecrasait GitHub, jamais reconstruit
# cote gitlab.com) : la propagation se fait a la main (git push origin).

resource "gitlab_project" "platform_gitops" {
  name             = "platform-gitops"
  path             = "platform-gitops"
  namespace_id     = gitlab_group.infra.id
  description      = "GitOps source de vérité — importé depuis GitHub"
  visibility_level = "private"
  import_url       = "${local.github_base}/platform-gitops.git"

  merge_method                     = "merge"
  squash_option                    = "default_off"
  remove_source_branch_after_merge = true
}

resource "gitlab_branch_protection" "platform_gitops_main" {
  project            = gitlab_project.platform_gitops.id
  branch             = "main"
  push_access_level  = "maintainer"
  merge_access_level = "developer"
  allow_force_push   = false
}
