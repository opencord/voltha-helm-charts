# voltha-helm-charts

This repo contains charts used with helm to start VOLTHA 2.0 and later.

## Testing

On patchset submission, jobs are run in Jenkins that validate the correctness
of the helm charts.

The code for these jobs can be found in
[helm-repo-tools](https://gerrit.opencord.org/gitweb?p=helm-repo-tools.git;a=tree)

The two scripts that should be run to test are:

 - `helm_lint.sh`
 - `chart_version_check.sh`

