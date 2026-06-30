locals {
  github_base = "https://github.com/poc-devops-elkouhen"
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

resource "gitlab_group_variable" "ci_templates_ref" {
  group             = gitlab_group.infra.id
  key               = "CI_TEMPLATES_REF"
  value             = "v1.13.1"
  protected         = false
  masked            = false
  environment_scope = "*"
}

# ── Projet sandbox pour valider le workflow IaC ───────────────────────────────

resource "gitlab_project" "sandbox" {
  name                   = "sandbox"
  path                   = "sandbox"
  namespace_id           = gitlab_group.infra.id
  description            = "Projet de test géré par Terraform"
  visibility_level       = "private"
  initialize_with_readme = true

  merge_method                     = "merge"
  squash_option                    = "default_off"
  remove_source_branch_after_merge = true
}

resource "gitlab_branch_protection" "sandbox_main" {
  project            = gitlab_project.sandbox.id
  branch             = "main"
  push_access_level  = "maintainer"
  merge_access_level = "developer"
  allow_force_push   = false
}

# ── Projets applicatifs importés depuis GitHub ────────────────────────────────

resource "gitlab_project" "helloworld" {
  name             = "helloworld"
  path             = "helloworld"
  description      = "Application helloworld — importé depuis GitHub"
  visibility_level = "private"
  import_url       = "${local.github_base}/helloworld.git"

  initialize_with_readme           = false
  merge_method                     = "merge"
  squash_option                    = "default_off"
  remove_source_branch_after_merge = true
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
  description      = "IaC helloworld — importé depuis GitHub"
  visibility_level = "private"
  import_url       = "${local.github_base}/helloworld-iac.git"

  initialize_with_readme           = false
  merge_method                     = "merge"
  squash_option                    = "default_off"
  remove_source_branch_after_merge = true
}

resource "gitlab_branch_protection" "helloworld_iac_main" {
  project            = gitlab_project.helloworld_iac.id
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
