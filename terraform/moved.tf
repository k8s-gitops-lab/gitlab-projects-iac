# Refactor des projets applicatifs codés en dur vers un for_each piloté par
# var.apps (généré depuis platform-gitops). Ces blocs évitent un destroy+create
# des projets GitLab existants (approvePlan est "auto" sur ce Terraform : un
# plan destructeur s'appliquerait sans revue humaine).
moved {
  from = gitlab_project.helloworld
  to   = gitlab_project.app["helloworld"]
}

moved {
  from = gitlab_project.helloworld_iac
  to   = gitlab_project.app["helloworld-iac"]
}

moved {
  from = gitlab_branch_protection.helloworld_main
  to   = gitlab_branch_protection.app_main["helloworld"]
}

moved {
  from = gitlab_branch_protection.helloworld_iac_main
  to   = gitlab_branch_protection.app_main["helloworld-iac"]
}

moved {
  from = gitlab_project_mirror.helloworld_to_github
  to   = gitlab_project_mirror.app_to_github["helloworld"]
}

moved {
  from = gitlab_project_mirror.helloworld_iac_to_github
  to   = gitlab_project_mirror.app_to_github["helloworld-iac"]
}
