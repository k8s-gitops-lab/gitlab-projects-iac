# AGENTS.md — gitlab-projects-iac

## Rôle du dépôt

Déclare en Terraform les projets GitLab de la plateforme (groupe `infra`,
variables CI/CD partagées, projets applicatifs et `platform-gitops` lui-même).
Appliqué automatiquement par le `Terraform` Flux CR `gitlab-iac`
(`platform-gitops/argocd/platform/tf-controller/terraform-gitlab.yaml`),
`approvePlan: auto` — **tout push sur `main` est appliqué sans revue humaine**.

## Fichiers clés

| Fichier | Rôle |
|---------|------|
| `terraform/main.tf` | Groupe `infra`, variables CI/CD (dont `GITHUB_TOKEN`), projets GitLab (`gitlab_project.app` en `for_each`), projet `platform-gitops`, mirroring vers GitHub |
| `terraform/variables.tf` | Déclare `var.apps` (liste `{name, description, importFromGithub}`) consommée par le `for_each` |
| `terraform/apps.auto.tfvars.json` | **Généré** par `toolbox/scripts/render-gitlab-projects.py` depuis l'inventaire `platform-gitops` (`argocd/apps/*.yaml`) — ne pas éditer à la main |
| `terraform/moved.tf` | Blocs `moved` de la migration hardcodé → `for_each` (ne pas supprimer sans vérifier que le state a bien été migré) |

## Modèle des projets applicatifs

- **Nouvelles apps** (`importFromGithub: false`, défaut) : créées **vides** sur
  GitLab (pas d'`import_url`) — leur code n'existe pas encore sur GitHub. Elles
  sont ensuite mirorées vers GitHub via `gitlab_project_mirror.app_to_github`
  une fois du contenu poussé.
- **Apps historiques** (`importFromGithub: true`, ex. `helloworld`) : importées
  depuis un repo GitHub préexistant, puis mirorées de la même façon.
- `platform-gitops` suit toujours le mode "historique" (`gitlab_project.platform_gitops`
  avec `import_url`) : les MR se font directement sur ce projet GitLab, et le
  push mirror (`gitlab_project_mirror.platform_gitops_to_github`) propage vers
  GitHub pour qu'ArgoCD/Flux continuent de le surveiller sans changement.

## Ce qu'il ne faut pas faire

- Ne pas éditer `apps.auto.tfvars.json` à la main : il est écrasé au prochain
  passage du pipeline `.gitlab-ci.yml` de `platform-gitops`.
- Ne pas ajouter de nouvel app en dur dans `main.tf` : passer par une MR sur
  `platform-gitops/argocd/apps/<app>.yaml`.
- Ne pas mettre `importFromGithub: true` pour une nouvelle app dont le code
  n'existe pas déjà sur GitHub : GitLab échouerait à l'import.
- Ne pas retirer les blocs `moved` sans vérifier au préalable (`terraform
  state list`) que les adresses ont bien été migrées — `approvePlan: auto`
  n'offre aucun filet de sécurité en cas de plan destructeur.
