# AGENTS.md — gitlab-projects-iac

## Rôle du dépôt

Déclare en Terraform les projets GitLab de la plateforme (groupe `infra`,
variables CI/CD partagées, projets applicatifs importés/mirorés depuis
GitHub). Appliqué automatiquement par le `Terraform` Flux CR `gitlab-iac`
(`platform-gitops/argocd/platform/tf-controller/terraform-gitlab.yaml`),
`approvePlan: auto` — **tout push sur `main` est appliqué sans revue humaine**.

## Fichiers clés

| Fichier | Rôle |
|---------|------|
| `terraform/main.tf` | Groupe `infra`, variables CI/CD, projets GitLab (`gitlab_project.app` en `for_each`), mirroring GitHub |
| `terraform/variables.tf` | Déclare `var.apps` (liste `{name, description}`) consommée par le `for_each` |
| `terraform/apps.auto.tfvars.json` | **Généré** par `toolbox/scripts/render-gitlab-projects.py` depuis l'inventaire `platform-gitops` (`argocd/apps/*.yaml`) — ne pas éditer à la main |
| `terraform/moved.tf` | Blocs `moved` de la migration hardcodé → `for_each` (ne pas supprimer sans vérifier que le state a bien été migré) |

## Ce qu'il ne faut pas faire

- Ne pas éditer `apps.auto.tfvars.json` à la main : il est écrasé au prochain
  passage du bot CI (workflow `onboard-apps.yml` dans `platform-gitops`).
- Ne pas ajouter de nouvel app en dur dans `main.tf` : passer par une PR sur
  `platform-gitops/argocd/apps/<app>.yaml`.
- Ne pas retirer les blocs `moved` sans vérifier au préalable (`terraform
  state list`) que les adresses ont bien été migrées — `approvePlan: auto`
  n'offre aucun filet de sécurité en cas de plan destructeur.
