# Spec technique

## Fichiers Terraform

- `terraform/main.tf` : ressources `gitlab_application_settings`,
  `gitlab_group.infra`, variables de groupe, `gitlab_group.app` (un groupe
  top-level par app) et leurs variables/memberships dupliquées, projets
  applicatifs (`gitlab_project.app` en `for_each` sur `local.app_projects`),
  protections de branche, `gitlab_group.shared_ci` et son projet
  `ci-templates`, projet `platform-gitops`, et les `gitlab_project_mirror`
  vers GitHub.
- `terraform/variables.tf` : déclare `var.gitlab_url`, `var.gitlab_token`
  (sensible), `var.github_token` (sensible) et `var.apps` (liste
  `{name, group, description, importFromGithub}`), consommée par le
  `for_each`.
- `terraform/apps.auto.tfvars.json` : généré par
  `toolbox/scripts/render-gitlab-projects.py` depuis l'inventaire
  `platform-gitops` (`argocd/apps/*.yaml`) — ne pas éditer à la main.
- `terraform/moved.tf` : blocs `moved` de la migration hardcodé → `for_each`,
  à ne pas supprimer sans vérifier au préalable que le state a bien été
  migré (`terraform state list`).
- `terraform/providers.tf`, `terraform/versions.tf` : configuration du
  provider GitLab et des versions Terraform.

## `local.app_projects` et `local.app_groups`

`app_projects` dérive de `var.apps` deux entrées par app : `<name>` (repo de
code) et `<name>-iac` (repo manifests), chacune avec sa description, son flag
`import_from_github` et le nom de son groupe (`group`, ex. `hello-groupe`).

`app_groups` dérive de `var.apps` une entrée par app, indexée par nom de
groupe (`{ "hello-groupe" = "helloworld", ... }`), consommée par le
`for_each` de `gitlab_group.app`.

## Groupe dédié par app

Chaque app a son propre groupe GitLab top-level (`gitlab_group.app`, ex.
`hello-groupe` pour `helloworld`), déclaré explicitement via le champ
`group` du descriptor `platform-gitops/argocd/apps/<app>.yaml` — pas dérivé
automatiquement du nom de l'app. Ce groupe est indépendant de `infra` (pas de
lien hiérarchique, donc pas d'héritage des variables de groupe `infra`) :
c'est un choix délibéré d'isolation par app plutôt qu'un sous-groupe partagé.

Conséquence directe de cette indépendance : rien n'est hérité entre groupes
top-level. Deux choses sont donc dupliquées explicitement par groupe d'app
(`for_each` sur `local.app_groups`) :

- les variables `GHCR_TOKEN`, `ZSCALER_CA_B64`, `GITLAB_PUSH_TOKEN` (mêmes
  valeurs que sur `infra`, cf. `local.zscaler_ca_b64` pour éviter de
  dupliquer le blob CA en clair dans le code) ;
- l'accès du bot `GITLAB_PUSH_TOKEN` (`gitlab_user.ci_push`, membre de
  `infra` via `gitlab_group_membership.ci_push_infra`) via
  `gitlab_group_membership.ci_push_app`, au niveau `maintainer` requis pour
  pousser sur les branches protégées des repos de code/manifests de l'app.

## Projets applicatifs

`gitlab_project.app` crée un projet par entrée de `local.app_projects`, dans
le namespace du groupe dédié de l'app (`gitlab_group.app[each.value.group]`),
en visibilité privée, avec merge method `merge` et squash désactivé par
défaut. `import_url` n'est renseigné que si `import_from_github` est vrai ;
sinon le projet est créé vide. `gitlab_branch_protection.app_main` protège
`main` (push réservé aux maintainers, merge ouvert aux developers,
force-push interdit).

## Groupe `shared-ci` et projet `ci-templates`

`gitlab_group.shared_ci` est un groupe top-level, indépendant de `infra` et
des groupes d'app (pas de lien hiérarchique, donc pas d'héritage de
variables). `gitlab_project.ci_templates` y est créé (namespace `shared-ci`),
importé depuis GitHub. `gitlab_branch_protection.ci_templates_main` protège
`main` avec les mêmes règles que les projets applicatifs.

Ce projet n'a pas de `.gitlab-ci.yml` à sa racine (pas de pipeline propre) :
son fichier `gitlab-ci.yml` n'est consommé que via `include:` par les
pipelines des apps. Comme ces apps vivent dans des groupes distincts de
`shared-ci`, aucune variable de groupe n'a besoin d'y être dupliquée — seul
`gitlab_group_membership.ci_push_shared_ci` (niveau `reporter`) donne au bot
`GITLAB_PUSH_TOKEN` le droit de cloner `shared-ci/ci-templates` (job
`.fetch-scripts`) depuis n'importe quel groupe d'app.

Note : ce bot est un utilisateur GitLab dédié (`gitlab_user.ci_push`), pas un
Group/Project Access Token. GitLab refuse qu'un bot issu d'un access token
soit ajouté comme membre d'un groupe/projet autre que celui qui l'a émis
("project bots cannot be added to other groups / projects"), ce qui aurait
cassé cet accès cross-groupe ; un utilisateur réel n'a pas cette
restriction.

## Mirroring vers GitHub

`gitlab_project_mirror.app_to_github` et
`gitlab_project_mirror.platform_gitops_to_github` poussent en continu vers
les dépôts GitHub canoniques (`keep_divergent_refs = false`), via une URL
`oauth2:${var.github_token}@...`. C'est ce mirror qui alimente Flux/ArgoCD,
lesquels surveillent GitHub et non GitLab.

## Variables de groupe (`infra`)

`infra` ne porte plus que `platform-gitops` et les ressources d'infrastructure
elles-mêmes (les apps ont leur propre groupe, cf. plus haut). Ses variables
restent la source de vérité dupliquée vers chaque groupe d'app :

| Variable | Usage |
|---|---|
| `GHCR_TOKEN` | Token pour push/pull sur GHCR (registre applicatif réel, `ghcr.io`), utilisé par les pipelines d'app (job `.build` de `ci-templates`) |
| `ZSCALER_CA_B64` | CA interceptée par le proxy Zscaler, encodée en base64 |
| `CI_TEMPLATES_REF` | Référence (tag) des templates CI/CD partagés à utiliser |
| `GITHUB_TOKEN` | Réutilisation du token GitHub fourni à Terraform, exposé aux pipelines GitLab CI de `platform-gitops` |
| `GITLAB_PUSH_TOKEN` | Personal Access Token (`gitlab_personal_access_token.ci_push`) d'un utilisateur de service dédié (`gitlab_user.ci_push`), scopes `api`, `read_repository`, `write_repository` ; dupliqué sur chaque groupe d'app, qui l'utilisent pour cloner `shared-ci/ci-templates` (`.fetch-scripts`) et pousser sur leurs propres repos (`deploy.py`, `semantic-release`) |

## Sécurité et limites

`approvePlan: auto` sur le CR Flux `gitlab-iac` signifie qu'aucun plan n'est
soumis à validation humaine avant application : un plan destructeur (ex.
suppression accidentelle des blocs `moved`) s'applique directement. Les
tokens sensibles (`gitlab_token`, `github_token`) sont fournis en variables
Terraform marquées `sensitive` et ne doivent jamais apparaître en clair dans
le code versionné.

Le passage des projets applicatifs du namespace `infra` vers leur groupe
dédié (`namespace_id` de `gitlab_project.app`) est un changement en place
supporté par le provider GitLab (transfert de projet), pas un destroy+create
— mais comme `approvePlan` est `auto`, il vaut mieux vérifier `terraform
plan` sur un poste avec accès au cluster avant de merger, faute de second
regard humain avant application.
