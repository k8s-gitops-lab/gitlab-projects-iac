# Spec technique

## Fichiers Terraform

- `terraform/main.tf` : ressources `gitlab_application_settings`,
  `gitlab_group.infra`, variables de groupe, projets applicatifs
  (`gitlab_project.app` en `for_each` sur `local.app_projects`), protections
  de branche, `gitlab_group.shared_ci` et son projet `ci-templates`, projet
  `platform-gitops`, et les `gitlab_project_mirror` vers GitHub.
- `terraform/variables.tf` : déclare `var.gitlab_url`, `var.gitlab_token`
  (sensible), `var.github_token` (sensible) et `var.apps` (liste
  `{name, description, importFromGithub}`), consommée par le `for_each`.
- `terraform/apps.auto.tfvars.json` : généré par
  `toolbox/scripts/render-gitlab-projects.py` depuis l'inventaire
  `platform-gitops` (`argocd/apps/*.yaml`) — ne pas éditer à la main.
- `terraform/moved.tf` : blocs `moved` de la migration hardcodé → `for_each`,
  à ne pas supprimer sans vérifier au préalable que le state a bien été
  migré (`terraform state list`).
- `terraform/providers.tf`, `terraform/versions.tf` : configuration du
  provider GitLab et des versions Terraform.

## `local.app_projects`

Dérive de `var.apps` deux entrées par app : `<name>` (repo de code) et
`<name>-iac` (repo manifests), chacune avec sa description et son flag
`import_from_github`.

## Projets applicatifs

`gitlab_project.app` crée un projet par entrée de `local.app_projects`, dans
le namespace `infra`, en visibilité privée, avec merge method `merge` et
squash désactivé par défaut. `import_url` n'est renseigné que si
`import_from_github` est vrai ; sinon le projet est créé vide.
`gitlab_branch_protection.app_main` protège `main` (push réservé aux
maintainers, merge ouvert aux developers, force-push interdit).

## Groupe `shared-ci` et projet `ci-templates`

`gitlab_group.shared_ci` est un groupe top-level, indépendant de `infra` (pas
de lien hiérarchique, donc pas d'héritage des variables de groupe `infra`).
`gitlab_project.ci_templates` y est créé (namespace `shared-ci`), importé
depuis GitHub. `gitlab_branch_protection.ci_templates_main` protège `main`
avec les mêmes règles que les projets applicatifs.

Ce projet n'a pas de `.gitlab-ci.yml` à sa racine (pas de pipeline propre) :
son fichier `gitlab-ci.yml` n'est consommé que via `include:` par les
pipelines des apps, lesquelles s'exécutent dans le namespace `infra` et
héritent donc normalement des variables du groupe `infra` (`GHCR_TOKEN`,
`ZSCALER_CA_B64`, `GITLAB_PUSH_TOKEN`). Aucune variable de groupe n'a donc
besoin d'être dupliquée sur `shared-ci`.

## Mirroring vers GitHub

`gitlab_project_mirror.app_to_github` et
`gitlab_project_mirror.platform_gitops_to_github` poussent en continu vers
les dépôts GitHub canoniques (`keep_divergent_refs = false`), via une URL
`oauth2:${var.github_token}@...`. C'est ce mirror qui alimente Flux/ArgoCD,
lesquels surveillent GitHub et non GitLab.

## Variables de groupe (`infra`)

| Variable | Usage |
|---|---|
| `GHCR_TOKEN` | Token pour push/pull sur GHCR (registre applicatif réel, `ghcr.io`), utilisé par `ci-templates` |
| `ZSCALER_CA_B64` | CA interceptée par le proxy Zscaler, encodée en base64 |
| `CI_TEMPLATES_REF` | Référence (tag) des templates CI/CD partagés à utiliser |
| `GITHUB_TOKEN` | Réutilisation du token GitHub fourni à Terraform, exposé aux pipelines GitLab CI de `platform-gitops` |
| `GITLAB_PUSH_TOKEN` | Group Access Token dédié (`gitlab_group_access_token.ci_push`), scopes `api`, `read_repository`, `write_repository`, pour les pipelines applicatifs (héritée par les apps dans `infra`, qui l'utilisent pour cloner `shared-ci/ci-templates` via le job `.fetch-scripts`) |

## Sécurité et limites

`approvePlan: auto` sur le CR Flux `gitlab-iac` signifie qu'aucun plan n'est
soumis à validation humaine avant application : un plan destructeur (ex.
suppression accidentelle des blocs `moved`) s'applique directement. Les
tokens sensibles (`gitlab_token`, `github_token`) sont fournis en variables
Terraform marquées `sensitive` et ne doivent jamais apparaître en clair dans
le code versionné.
