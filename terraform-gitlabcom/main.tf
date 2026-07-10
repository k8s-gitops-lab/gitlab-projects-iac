# Phase 1 de la migration GitLab self-hosted -> gitlab.com (cf.
# cockpit/docs/backlog.md, section "Migration GitLab self-hosted ->
# GitLab.com"). Perimetre volontairement minimal : structure de
# groupes/projets + validation du push, rien de plus. Pas de variables
# CI/CD, pas de branch protection, pas de gitlab_project_mirror, pas
# d'utilisateur de service -- cf. terraform/main.tf (instance locale) pour
# ce que ce module devra eventuellement absorber lors du cutover CI.

resource "gitlab_group" "root" {
  name             = "k8s-gitops-lab"
  path             = "k8s-gitops-lab"
  description      = "POC CI/CD GitOps -- groupe racine (migration depuis le GitLab self-hosted local)"
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
