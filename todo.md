# chart_version_check.md reporting enhancement

## voltha/Chart.yaml

- voltha-adapter-openolt/Chart.yaml version string was updated.
- Not immediately obvious why voltha/Chart.yaml was in error.
- Update reporting to display the dependency chain, voltha requires
  a version bump due to voltha-infra and/or voltha-stack being updated.

| Chart                  | Dependency                |
| ---------------------- | ------------------------- |
| voltha                 | voltha-infra voltha-stack |
| voltha-infra           | voltha-adapter-openolt    |
| voltha-stack           | voltha-adapter-openolt    |
| voltha-adapter-openolt | null                      |
    

> [CHART] voltha/Chart.yaml                                            (2.12.11)
>     Modified Files (files changed): voltha
>         voltha-adapter-openolt/templates/_helpers.tpl
>   voltha-adapter-openolt/templates/openolt-deploy.yaml
>   voltha-adapter-openolt/templates/openolt-profile-svc.yaml
>   voltha-adapter-openolt/templates/openolt-svc.yaml
>   voltha-adapter-openolt/values.yaml
> 
>   Files contributing to chart delta:
>   makefiles/lint/helm/chart.mk
>   voltha-adapter-openolt/Chart.yaml
>   voltha-adapter-openolt/templates/_helpers.tpl
>   voltha-adapter-openolt/templates/openolt-deploy.yaml
>   voltha-adapter-openolt/templates/openolt-profile-svc.yaml
>   voltha-adapter-openolt/templates/openolt-svc.yaml
>   voltha-adapter-openolt/values.yaml
>   voltha-infra/Chart.yaml
>   voltha-stack/Chart.yaml
> [ERROR] Chart modified but version unchanged: voltha/Chart.yaml (2.12.11)
