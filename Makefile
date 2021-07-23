branch=`cat .gitreview | grep branch | cut -d '=' -f2`

help: # @HELP Print the command options
	@echo
	@echo "\033[0;31m    VOLTHA HELM CHARTS \033[0m"
	@echo
	@grep -E '^.*: .* *# *@HELP' $(MAKEFILE_LIST) \
    | sort \
    | awk ' \
        BEGIN {FS = ": .* *# *@HELP"}; \
        {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}; \
    '

tagcollisionreject.sh:
	@curl -o tagcollisionreject.tmp.sh https://raw.githubusercontent.com/opencord/ci-management/master/jjb/shell/tagcollisionreject.sh
	@echo 6dc8352d47f415e003dbddc30ede194ca304907d25f1c2a384f928083194860f tagcollisionreject.tmp.sh | sha256sum --check
	@mv tagcollisionreject.tmp.sh	tagcollisionreject.sh

test-tags: tagcollisionreject.sh
	@bash ./tagcollisionreject.sh

helm-repo-tools:
	git clone "https://gerrit.opencord.org/helm-repo-tools"

test: test-tags helm-repo-tools # @HELP Makes sure the versions used in the charts are valid
	@COMPARISON_BRANCH=origin/$(branch) ./helm-repo-tools/chart_version_check.sh

clean: # @HELP Removes all files downloaded to run the tests
	rm -rf helm-repo-tools
	rm tagcollisionreject.*
