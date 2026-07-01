# gitlab-projects-iac

Terraform qui déclare les projets GitLab de la plateforme : groupe `infra`,
variables CI/CD partagées, projets applicatifs (générés depuis l'inventaire
`platform-gitops`) et le projet `platform-gitops` lui-même.

Appliqué automatiquement par le `Terraform` Flux CR `gitlab-iac`
(`platform-gitops/argocd/platform/tf-controller/terraform-gitlab.yaml`),
avec `approvePlan: auto` : tout push sur `main` est appliqué sans revue
humaine.

## Structure

- `terraform/main.tf` : groupe `infra`, variables CI/CD, projets GitLab, mirroring vers GitHub.
- `terraform/variables.tf` : déclare `var.apps`, consommée par le `for_each` des projets applicatifs.
- `terraform/apps.auto.tfvars.json` : généré par `toolbox/scripts/render-gitlab-projects.py` depuis `platform-gitops/argocd/apps/*.yaml` — ne pas éditer à la main.
- `terraform/moved.tf` : blocs `moved` de la migration hardcodé → `for_each`.

## Documentation

- `docs/spec-fonctionnelle.md` : rôle du dépôt, modèle des projets applicatifs.
- `docs/spec-technique.md` : ressources Terraform, variables, mirroring.

Voir aussi `AGENTS.md` pour les règles opérateur/agent (ce qu'il ne faut pas
faire).
