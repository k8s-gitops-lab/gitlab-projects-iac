output "repo_urls" {
  description = "URL HTTPS de push par repo, pour ajouter le remote gitlab"
  value = merge(
    {
      for name, project in gitlab_project.app : name => project.http_url_to_repo
    },
    {
      platform-gitops = gitlab_project.platform_gitops.http_url_to_repo
      ci-templates    = gitlab_project.ci_templates.http_url_to_repo
    }
  )
}
