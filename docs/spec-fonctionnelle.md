# Spec fonctionnelle

## Rôle du dépôt

Le dépôt déclare en Terraform les projets GitLab de la plateforme : le groupe
`infra`, les variables CI/CD partagées, les projets applicatifs et le projet
`platform-gitops` lui-même. Il est la source de vérité de l'organisation
GitLab, au même titre que `platform-gitops` l'est pour l'état Kubernetes.

## Application automatique

Le Terraform Flux CR `gitlab-iac`
(`platform-gitops/argocd/platform/tf-controller/terraform-gitlab.yaml`)
applique ce dépôt avec `approvePlan: auto`. Tout push sur `main` est donc
appliqué sans revue humaine ni plan intermédiaire à valider : les changements
doivent être vérifiés avant merge, pas après.

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

## Origine de l'inventaire des apps

La liste des apps (`terraform/apps.auto.tfvars.json`) n'est pas éditée à la
main : elle est générée par `toolbox/scripts/render-gitlab-projects.py` à
partir de l'inventaire déclaré dans `platform-gitops/argocd/apps/*.yaml`.
Ajouter une app se fait donc côté `platform-gitops`, pas dans ce dépôt.

## Variables CI/CD partagées

Le groupe `infra` porte les variables consommées par les pipelines des
projets qu'il contient : URL de registry, token GHCR, CA Zscaler, référence
des templates CI, token GitHub pour le mirroring, et un token GitLab dédié
(`GITLAB_PUSH_TOKEN`) pour les pipelines applicatifs qui doivent pousser des
commits ou créer des tags/releases.
