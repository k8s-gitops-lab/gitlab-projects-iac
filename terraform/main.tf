locals {
  github_base = "https://github.com/poc-devops-elkouhen"
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

resource "gitlab_group_variable" "ci_templates_ref" {
  group             = gitlab_group.infra.id
  key               = "CI_TEMPLATES_REF"
  value             = "v1.14.0"
  protected         = false
  masked            = false
  environment_scope = "*"
}


# ── Projets applicatifs importés depuis GitHub ────────────────────────────────

resource "gitlab_project" "helloworld" {
  name             = "helloworld"
  path             = "helloworld"
  namespace_id     = gitlab_group.infra.id
  description      = "Application helloworld — importé depuis GitHub"
  visibility_level = "private"
  import_url       = "${local.github_base}/helloworld.git"

  merge_method                     = "merge"
  squash_option                    = "default_off"
  remove_source_branch_after_merge = true

  depends_on = [gitlab_application_settings.main]
}

resource "gitlab_branch_protection" "helloworld_main" {
  project            = gitlab_project.helloworld.id
  branch             = "main"
  push_access_level  = "maintainer"
  merge_access_level = "developer"
  allow_force_push   = false
}

resource "gitlab_project" "helloworld_iac" {
  name             = "helloworld-iac"
  path             = "helloworld-iac"
  namespace_id     = gitlab_group.infra.id
  description      = "IaC helloworld — importé depuis GitHub"
  visibility_level = "private"
  import_url       = "${local.github_base}/helloworld-iac.git"

  merge_method                     = "merge"
  squash_option                    = "default_off"
  remove_source_branch_after_merge = true

  depends_on = [gitlab_application_settings.main]
}

resource "gitlab_branch_protection" "helloworld_iac_main" {
  project            = gitlab_project.helloworld_iac.id
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

# ── Mirroring GitLab → GitHub ─────────────────────────────────────────────────

resource "gitlab_project_mirror" "helloworld_to_github" {
  project             = gitlab_project.helloworld.id
  url                 = "https://oauth2:${var.github_token}@github.com/poc-devops-elkouhen/helloworld.git"
  enabled             = true
  keep_divergent_refs = false
}

resource "gitlab_project_mirror" "helloworld_iac_to_github" {
  project             = gitlab_project.helloworld_iac.id
  url                 = "https://oauth2:${var.github_token}@github.com/poc-devops-elkouhen/helloworld-iac.git"
  enabled             = true
  keep_divergent_refs = false
}
