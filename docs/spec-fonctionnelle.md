# Spec fonctionnelle

## Rôle du dépôt

Le dépôt déclare en Terraform les projets GitLab de la plateforme : le groupe
`infra` et ses variables CI/CD partagées, un groupe dédié par app (avec ses
projets applicatifs), le groupe `shared-ci` et son projet `ci-templates`, et
le projet `platform-gitops` lui-même. Il est la source de vérité de
l'organisation GitLab, au même titre que `platform-gitops` l'est pour l'état
Kubernetes.

## Application automatique

Le Terraform Flux CR `gitlab-iac`
(`platform-gitops/argocd/platform/tf-controller/terraform-gitlab.yaml`)
applique ce dépôt avec `approvePlan: auto`. Tout push sur `main` est donc
appliqué sans revue humaine ni plan intermédiaire à valider : les changements
doivent être vérifiés avant merge, pas après.

L'état Terraform (`terraform/versions.tf`, backend `kubernetes`) est stocké
dans un `Secret` du namespace `flux-system` du cluster — pas de state local.
Pour un dry-run avant merge, il faut donc soit exécuter `terraform plan`
depuis un poste avec accès au cluster (kubeconfig + `var.gitlab_token`/
`var.github_token`), soit se fier à la revue du diff `apps.auto.tfvars.json`
généré par `render-gitlab-projects.py` (voir "Origine de l'inventaire" plus
bas) : il n'y a pas de plan CI automatique exposé avant application.

## Modèle des projets applicatifs

- **Nouvelles apps** (`importFromGithub: false`, valeur par défaut) : créées
  vides sur GitLab, sans code préexistant. Elles sont ensuite mirorées vers
  GitHub une fois du contenu poussé.
- **Apps historiques** (`importFromGithub: true`, ex. `helloworld`) :
  importées depuis un repo GitHub préexistant, puis mirorées de la même
  façon.
- `platform-gitops` suit toujours le mode "historique" : les MR se font
  directement sur ce projet GitLab, et le push mirror propage vers GitHub
  pour qu'ArgoCD/Flux continuent de le surveiller sans changement de
  configuration.
- Chaque app est isolée dans son propre groupe GitLab top-level (`group`,
  ex. `hello-groupe` pour `helloworld`), déclaré explicitement dans son
  descriptor — pas dérivé du nom de l'app, et sans lien hiérarchique avec
  `infra`. Les repos de code et manifests d'une même app vivent tous deux
  dans ce groupe.

## Origine de l'inventaire des apps

La liste des apps (`terraform/apps.auto.tfvars.json`) n'est pas éditée à la
main : elle est générée par `toolbox/scripts/render-gitlab-projects.py` à
partir de l'inventaire déclaré dans `platform-gitops/argocd/apps/*.yaml`.
Ajouter une app se fait donc côté `platform-gitops`, pas dans ce dépôt.

## Variables CI/CD partagées

Le groupe `infra` porte les variables de référence : URL de registry, token
GHCR, CA Zscaler, référence des templates CI, token GitHub pour le
mirroring, et un token GitLab dédié (`GITLAB_PUSH_TOKEN`) pour les pipelines
qui doivent pousser des commits ou créer des tags/releases. Les groupes
d'app étant top-level et indépendants de `infra` (donc sans héritage), les
variables consommées par les pipelines applicatifs (`GHCR_TOKEN`,
`ZSCALER_CA_B64`, `GITLAB_PUSH_TOKEN`) sont dupliquées sur chaque groupe
d'app, de même que l'accès du bot `GITLAB_PUSH_TOKEN` à `shared-ci` (pour
cloner `ci-templates`) et à son propre groupe (pour pousser).
