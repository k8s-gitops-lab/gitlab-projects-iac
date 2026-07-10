output "repo_urls" {
  description = "URL HTTPS de push par repo, pour ajouter le remote gitlabcom"
  value = {
    platform-gitops = gitlab_project.platform_gitops.http_url_to_repo
    ci-templates    = gitlab_project.ci_templates.http_url_to_repo
    helloworld      = gitlab_project.helloworld.http_url_to_repo
    helloworld-iac  = gitlab_project.helloworld_iac.http_url_to_repo
  }
}
