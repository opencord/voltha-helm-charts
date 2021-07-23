branch=`cat .gitreview | grep branch | cut -d '=' -f2`

tagcollisionreject.sh:
	@wget https://raw.githubusercontent.com/opencord/ci-management/master/jjb/shell/tagcollisionreject.sh

test-tags: tagcollisionreject.sh
	@bash ./tagcollisionreject.sh

helm-repo-tools:
	git clone "ssh://teone@gerrit.opencord.org:29418/helm-repo-tools"

test: test-tags helm-repo-tools
	@COMPARISON_BRANCH=origin/$(branch) ./helm-repo-tools/chart_version_check.sh
