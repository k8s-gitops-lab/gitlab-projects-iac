locals {
  github_base = "https://github.com/poc-devops-elkouhen"

  # Une entrée par projet GitLab applicatif : le repo de code (<name>) et son
  # repo manifests (<name>-iac), dérivés de var.apps (généré depuis
  # platform-gitops/argocd/apps/*.yaml — cf. toolbox/scripts/render-gitlab-projects.py).
  app_projects = merge([
    for app in var.apps : {
      "${app.name}" = {
        name               = app.name
        description        = app.description != "" ? app.description : "Application ${app.name}${app.importFromGithub ? " — importé depuis GitHub" : ""}"
        import_from_github = app.importFromGithub
      }
      "${app.name}-iac" = {
        name               = "${app.name}-iac"
        description        = "IaC ${app.name}${app.description != "" ? " — ${app.description}" : ""}${app.importFromGithub ? " — importé depuis GitHub" : ""}"
        import_from_github = app.importFromGithub
      }
    }
  ]...)
}

# ── Paramètres application GitLab ─────────────────────────────────────────────

resource "gitlab_application_settings" "main" {
  import_sources = ["git"]
}

# ── Groupe dédié aux ressources gérées par Terraform ─────────────────────────

resource "gitlab_group" "infra" {
  name             = "infra"
  path             = "infra"
  description      = "Ressources infrastructure gérées par Terraform via tf-controller"
  visibility_level = "private"
}

# ── Variables CI/CD du groupe infra ──────────────────────────────────────────

resource "gitlab_group_variable" "registry_url" {
  group             = gitlab_group.infra.id
  key               = "REGISTRY_URL"
  value             = "registry.192.168.33.100.nip.io"
  protected         = false
  masked            = false
  environment_scope = "*"
}

resource "gitlab_group_variable" "ghcr_token" {
  group             = gitlab_group.infra.id
  key               = "GHCR_TOKEN"
  value             = var.github_token
  protected         = false
  masked            = true
  environment_scope = "*"
}

resource "gitlab_group_variable" "zscaler_ca_b64" {
  group             = gitlab_group.infra.id
  key               = "ZSCALER_CA_B64"
  value             = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUU2RENDQTlDZ0F3SUJBZ0lKQU51K21DMkp0M3VUTUEwR0NTcUdTSWIzRFFFQkN3VUFNSUdoTVFzd0NRWUQKVlFRR0V3SlZVekVUTUJFR0ExVUVDQk1LUTJGc2FXWnZjbTVwWVRFUk1BOEdBMVVFQnhNSVUyRnVJRXB2YzJVeApGVEFUQmdOVkJBb1RERnB6WTJGc1pYSWdTVzVqTGpFVk1CTUdBMVVFQ3hNTVduTmpZV3hsY2lCSmJtTXVNUmd3CkZnWURWUVFERXc5YWMyTmhiR1Z5SUZKdmIzUWdRMEV4SWpBZ0Jna3Foa2lHOXcwQkNRRVdFM04xY0hCdmNuUkEKZW5OallXeGxjaTVqYjIwd0lCY05NalV3TWpBeU1UWXpPREl3V2hnUE1qQTFNakEyTWpBeE5qTTRNakJhTUlHaApNUXN3Q1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVJNQThHQTFVRUJ4TUlVMkZ1CklFcHZjMlV4RlRBVEJnTlZCQW9UREZwelkyRnNaWElnU1c1akxqRVZNQk1HQTFVRUN4TU1Xbk5qWVd4bGNpQkoKYm1NdU1SZ3dGZ1lEVlFRREV3OWFjMk5oYkdWeUlGSnZiM1FnUTBFeElqQWdCZ2txaGtpRzl3MEJDUUVXRTNOMQpjSEJ2Y25SQWVuTmpZV3hsY2k1amIyMHdnZ0VpTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElCRHdBd2dnRUtBb0lCCkFRQ3BQdEpOTEZsRk9BUVVWL3AyZ2RxTkp6VytUbU9iT1l6b0ZhNDZqVGpnU3hwTnoxNVVSWDhlTWYvVU5iTm0KMXl0OU9QNmVMYlRscWt4T1VvRmJkUmhINlhJc2REMFdobUlOZGhjcnltZ3BKWG41T2JSV1d6L2twdnlhU0ZWVwpxL3N1QmdTYThSanNjOWo2TFdjUVprSnJqcGxjSTZpRW5TWUVTMEgwbFdXa01nNzZjM1NGUXdCaGgxblVwbFlJCncxL2tuOXBObUpLR3lpczNZRGZ5Skk2RjEzNlp4RXppSTB2ZUN3dTczMWVFcWRHb3FnZDRmemVWVjErN1ZjRjYKaERQUGxYcUFEZVJ0RytFUENnaVZNRjR4cm1YakpGMGtCOTJtUnNYT3FMQktBMTJGdkZNZWRoaWlzUE1wK3ZhcwpRVXgyd3hUUU1kMTRCbC92WFg3VUs2ZTVBZ01CQUFHamdnRWRNSUlCR1RBZEJnTlZIUTRFRmdRVXViZmRTczNECkRneUduVjNmN0J3RWFjVk9tTjh3RHdZRFZSMFRBUUgvQkFVd0F3RUIvekNCMWdZRFZSMGpCSUhPTUlITGdCUzUKdDkxS3pjTU9ESWFkWGQvc0hBUnB4VTZZMzZHQnA2U0JwRENCb1RFTE1Ba0dBMVVFQmhNQ1ZWTXhFekFSQmdOVgpCQWdUQ2tOaGJHbG1iM0p1YVdFeEVUQVBCZ05WQkFjVENGTmhiaUJLYjNObE1SVXdFd1lEVlFRS0V3eGFjMk5oCmJHVnlJRWx1WXk0eEZUQVRCZ05WQkFzVERGcHpZMkZzWlhJZ1NXNWpMakVZTUJZR0ExVUVBeE1QV25OallXeGwKY2lCU2IyOTBJRU5CTVNJd0lBWUpLb1pJaHZjTkFRa0JGaE56ZFhCd2IzSjBRSHB6WTJGc1pYSXVZMjl0Z2drQQoyNzZZTFltM2U1TXdEZ1lEVlIwUEFRSC9CQVFEQWdHR01BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQloyNTd1CjZ4Y0RuZnEzM0RoZGkwaC9nKzVrejV3dG8rMHcxVS95MlYzYkFmd096dlNpS2ZyT0dFc3NZTlZkdjE3cVNPVUMKakZzL2t2Q21ablMyWkFyL2lBeGVEOHFrQzZaYjU1NTJMUkNpVjRYSEJhZU42Q2QrWVRKTWdWS21CeEZyc3hsRQpQbWF1eE8xYUl3VGYzZVFtRCtuNVluN01rS0NsSWVka2Zyd0hxNHMzWnZ5dnlwbEF3alN3eWVzbUV6LzVHZGs5ClhkaHNmcklsV3E4RHlKaWpOR3lzQk9jZVlPQjZqbUNpanR3RkcwMnViQWZpSU1aL0JSQzgrTzd3anpEZ1JBTHoKT0MyK21ReXRTa0tvOEs2TXNrZkVkalFHWmN0S2FQSVNHMzQ0UFFZL3k0ektCZjFKTnBTZnNUQnphSTlsajdQSwptN3EyVHpNcDhzNUR1R2JLCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
  protected         = false
  masked            = false
  environment_scope = "*"
}

resource "gitlab_group_variable" "ci_templates_ref" {
  group             = gitlab_group.infra.id
  key               = "CI_TEMPLATES_REF"
  value             = "v1.15.0"
  protected         = false
  masked            = false
  environment_scope = "*"
}

# Réutilise le token GitHub déjà fourni au Terraform (var.github_token, utilisé
# pour le mirroring GitLab → GitHub) pour l'exposer au pipeline GitLab CI de
# platform-gitops : clone de platform-cicd/toolbox (privés) et push des commits
# générés vers les dépôts GitHub canoniques. Confirmé explicitement par
# l'utilisateur (duplication volontaire d'un secret existant vers une CI/CD
# variable GitLab).
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
  namespace_id     = gitlab_group.infra.id
  description      = each.value.description
  visibility_level = "private"
  import_url       = each.value.import_from_github ? "${local.github_base}/${each.value.name}.git" : null

  merge_method                     = "merge"
  squash_option                    = "default_off"
  remove_source_branch_after_merge = true

  depends_on = [gitlab_application_settings.main]
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
  namespace_id     = gitlab_group.infra.id
  description      = "Templates CI/CD partagés — importé depuis GitHub"
  visibility_level = "private"
  import_url       = "${local.github_base}/ci-templates.git"

  merge_method                     = "merge"
  squash_option                    = "default_off"
  remove_source_branch_after_merge = true

  depends_on = [gitlab_application_settings.main]
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
# depuis GitHub puis développement normal sur GitLab, comme les autres projets
# applicatifs ci-dessus. Le merge d'une MR déclenche directement le pipeline
# `.gitlab-ci.yml` (pas de mirror pull, pas de délai). Le pipeline pousse ses
# commits générés sur ce même projet (origin, via CI_JOB_TOKEN) ; le push
# mirror ci-dessous propage ensuite vers GitHub, dépôt que Flux/ArgoCD
# continuent de surveiller sans changement de configuration.

resource "gitlab_project" "platform_gitops" {
  name             = "platform-gitops"
  path             = "platform-gitops"
  namespace_id     = gitlab_group.infra.id
  description      = "GitOps source de vérité — importé depuis GitHub, mirroré vers GitHub"
  visibility_level = "private"
  import_url       = "${local.github_base}/platform-gitops.git"

  merge_method                     = "merge"
  squash_option                    = "default_off"
  remove_source_branch_after_merge = true

  depends_on = [gitlab_application_settings.main]
}

resource "gitlab_branch_protection" "platform_gitops_main" {
  project            = gitlab_project.platform_gitops.id
  branch             = "main"
  push_access_level  = "maintainer"
  merge_access_level = "developer"
  allow_force_push   = false
}

# ── Mirroring GitLab → GitHub ─────────────────────────────────────────────────

resource "gitlab_project_mirror" "app_to_github" {
  for_each = local.app_projects

  project             = gitlab_project.app[each.key].id
  url                 = "https://oauth2:${var.github_token}@github.com/poc-devops-elkouhen/${each.value.name}.git"
  enabled             = true
  keep_divergent_refs = false
}

resource "gitlab_project_mirror" "platform_gitops_to_github" {
  project             = gitlab_project.platform_gitops.id
  url                 = "https://oauth2:${var.github_token}@github.com/poc-devops-elkouhen/platform-gitops.git"
  enabled             = true
  keep_divergent_refs = false
}
