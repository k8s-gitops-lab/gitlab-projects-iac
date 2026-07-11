# Consolidation terraform-gitlabcom/ -> terraform/ (cf. cockpit/docs/backlog.md) :
# les groupes/projets applicatifs codés en dur passent au for_each piloté par
# var.apps. Ces blocs évitent un destroy+create du groupe et des deux projets
# existants (approvePlan est "auto" sur ce Terraform : un plan destructeur
# s'appliquerait sans revue humaine). Les projets seront tout de même
# recréés par Terraform à cause de l'ajout d'import_url (ForceNew) — c'est
# le but recherché (réimport du contenu depuis GitHub) — mais le groupe, lui,
# ne sera pas détruit.
moved {
  from = gitlab_group.hello_groupe
  to   = gitlab_group.app["hello-groupe"]
}

moved {
  from = gitlab_project.helloworld
  to   = gitlab_project.app["helloworld"]
}

moved {
  from = gitlab_project.helloworld_iac
  to   = gitlab_project.app["helloworld-iac"]
}
