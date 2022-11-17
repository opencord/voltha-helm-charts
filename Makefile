# -*- makefile -*-
# -----------------------------------------------------------------------
# Copyright 2021-2022 Open Networking Foundation (ONF) and the ONF Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# -----------------------------------------------------------------------

.DEFAULT_GOAL := help

##-------------------##
##---]  GLOBALS  [---##
##-------------------##
dot         ?= .
TOP         ?= $(dot)
MAKEDIR     ?= $(TOP)/makefiles

##--------------------##
##---]  INCLUDES  [---##
##--------------------##
include $(MAKEDIR)/include.mk

branch=`cat .gitreview | grep branch | cut -d '=' -f2`

help:: # @HELP Print the command options
	@echo "  test                          Sanity check chart versions"
	@echo
	@echo "[CHECK: release]"
	@echo "  helm-repo-tools               Repository clone target"
	@echo "  tagcollisionreject.sh         404 - raw.github source MIA"
	@echo
	@echo "\033[0;31m    VOLTHA HELM CHARTS \033[0m"
	@echo
	@grep -E '^.*: .* *# *@HELP' $(MAKEFILE_LIST) \
    | sort \
    | awk ' \
        BEGIN {FS = ": .* *# *@HELP"}; \
        {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}; \
    '

# -----------------------------------------------------------------------
# curl: 404: Not Found
#   https://raw.githubusercontent.com
# -----------------------------------------------------------------------
# github no longer supports usercontent retrieval, svc was used as a CDN.
# 3 distinct versions of tcr.sh are used by jenkins jobs.
# -----------------------------------------------------------------------
# Short term answer:
#   o Find something usable for interactive use.
# Long term answer:
#   o Refactor tcr.sh x [n] and support consistent functionality with a single script.
# -----------------------------------------------------------------------
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
	$(RM) -r helm-repo-tools
	$(RM) tagcollisionreject.*

# [EOF]
