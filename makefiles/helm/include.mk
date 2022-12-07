# -*- makefile -*-

helm-repo-tools:
	git clone "https://gerrit.opencord.org/helm-repo-tools"

clean ::
	$(RM) helm-repo-tools

# [EOF]
