# -*- makefile -*-
# -----------------------------------------------------------------------
# Copyright 2022 Open Networking Foundation (ONF) and the ONF Contributors
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
#
# SPDX-FileCopyrightText: 2022 Open Networking Foundation (ONF) and the ONF Contributors
# SPDX-License-Identifier: Apache-2.0
# -----------------------------------------------------------------------

GIT ?= /usr/bin/git

##--------------------##
##---]  INCLUDES  [---##
##--------------------##
include $(MAKEDIR)/lint/helm/tools.mk
include $(MAKEDIR)/lint/helm/branch-detect.mk
include $(MAKEDIR)/lint/helm/chart.mk
include $(MAKEDIR)/lint/helm/helm.mk

##-------------------##
##---]  TARGETS  [---##
##-------------------##

## -----------------------------------------------------------------------
## [TODO] Extract hardcoded values from lint.sh:
##    o pass as args
##    o pass through configs:
##    o consumer/makefile should prep then invoke htmllint:
##        + arbitrary repository commit hooks can match build behavior.
## -----------------------------------------------------------------------
lint-helm-deps:
	helm repo add stable https://charts.helm.sh/stable
	helm repo add rook-release https://charts.rook.io/release
	helm repo add cord https://charts.opencord.org

## -----------------------------------------------------------------------
## Intent: Display target help with context
##   % make help
##   % make help VERBOSE=1
## -----------------------------------------------------------------------
help ::
	@echo
	@echo '[LINT: helm]'
	@echo "  lint-chart                    chart_version_check.sh"

	@echo "  lint-helm                     Syntax check helm configs"
ifdef VERBOSE
	@echo '    COMPARISON_BRANCH="origin/master" make lint-chart'
endif

	@echo "  lint-helm-deps                Configure dependent helm charts"

## -----------------------------------------------------------------------
## Intent: Future enhancement list
## -----------------------------------------------------------------------
todo ::
	@ehco "[TODO: makefiles/helm/include.mk]"
	@echo " o Generalize script logic, remove hardcoded values,"
	@echo " o Update gerrit/jenkins/makefiles/interactive:"
	@echo "     Lint behavior should be consistent everywhere."
	@echo " o Fix COMPARSION_BRANCH logic:"
	@echo "     helm-repo-tools/chart_version_check contains 'opencord/master'"
	@echo " o Refactor 2 jenkins jobs and lint-helm-deps"
	@echo "     use everywhere: % make lint-helm"

# [EOF]
