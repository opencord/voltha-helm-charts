branch=`cat .gitreview | grep branch | cut -d '=' -f2`

tagcollisionreject.sh:
	@wget https://raw.githubusercontent.com/opencord/ci-management/master/jjb/shell/tagcollisionreject.sh

test-tags: tagcollisionreject.sh
	@bash ./tagcollisionreject.sh

test: test-tags
	git submodule init && git submodule update
	@COMPARISON_BRANCH=origin/$(branch) ./helm-repo-tools/chart_version_check.sh
