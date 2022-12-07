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

chart-version-check-sh := helm-repo-tools/chart_version_check.sh

## -------------------------------------------------------------------
## NOTE: This uglyness can go away with proper command line switch use
## -------------------------------------------------------------------
##   o USE_LEGACY= (default)
##       - bridge logic: support existing behavior.
##       - helmlint.sh contains hardcoded branch='origin/opencord'
##   o TODO:
##       - infer values from repository checkout on disk.
##       - parameterize helmlint.sh
##       - use simple flags to toggle behavior:
##           MASTER_BRANCH=1  || --branch master (default)
##           LOCAL_BRANCH=1   || --branch local)
##           MY_BRANCH=1      || --branch local
##       - Better yet: when branch name is known simply pass it:
##           % make lint-helm BRANCH=alt-branch-name
## -----------------------------------------------------------------------
USE_LEGACY = 1
ifdef USE_LEGACY
  $(if $(DEBUG),$(info ifdef USE_LEGACY))

  lint-helm-branch ?= $(shell cat .gitreview | grep branch | cut -d '=' -f2)

else
  $(if $(DEBUG),$(info not USE_LEGACY))

  ifdef LOCAL_BRANCH
     get-git-branch ?= $(shell $(GIT) branch --show-current)# empty if detached
     get-git-branch ?= $(shell awk -F '/branch/ {print $$2}' .gitreview)
     get-git-branch ?= $(error Detected detached head)

  else # master
     # refs/remotes/origin/HEAD => origin/master
     get-git-branch ?= $(shell $(GIT) symbolic-ref --short refs/remotes/origin/HEAD)
  endif

  lint-helm-branch ?= $(COMPARISON_BRANCH)
  lint-helm-branch ?= $(get-git-branch)

  $(if $(DEBUG),$(info get-git-branch = $(get-git-branch)))
  $(if $(DEBUG),$(info lint-branch=$(lint-branch)))
endif

##-------------------##
##---]  TARGETS  [---##
##-------------------##
.PHONY : lint-helm
lint   : lint-helm

## -----------------------------------------------------------------------
## Intent: Lint helm charts
##   o This logic mirrors gerrit/jenkins commit hook behavior.
##   o Adding to stem incidents of late pull request jenkins failures.
##   o see: make help VERBOSE=1
## -----------------------------------------------------------------------
.PHONY: lint-helm
lint-helm: $(chart-version-check-sh)# helm-repo-tools
lint-helm:
	COMPARISON_BRANCH="$(get-git-branch)" $(chart-version-check-sh)
#	COMPARISON_BRANCH="$(lint-helm-branch)" $(chart-version-check-sh)

## -----------------------------------------------------------------------
## Intent: repo:helm-repo-tools
##   o Use script as a dependency for on-demand cloning.
##   o Use of repo name (r-h-t) as a dependency is problematic.
## -----------------------------------------------------------------------
$(chart-version-check-sh):
	$(GIT) clone "https://gerrit.opencord.org/helm-repo-tools"

## -----------------------------------------------------------------------
## Intent: 
## -----------------------------------------------------------------------
# branch=`cat .gitreview | grep branch | cut -d '=' -f2`
pre-commit :: lint-helm
#	$(chart-version-check-sh) clean
#	@COMPARISON_BRANCH=origin/$(branch) $(chart-version-check-sh)
#	$(chart-version-check-sh)

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
## Intent: Remove generated targets
## -----------------------------------------------------------------------
clean ::
	$(chart-version-check-sh) clean

## -----------------------------------------------------------------------
## Intent: Remove all non-source targets
## -----------------------------------------------------------------------
sterile ::
	$(RM) helm-repo-tools

## -----------------------------------------------------------------------
## Intent: Display target help with context
##   % make help
##   % make help VERBOSE=1
## -----------------------------------------------------------------------
help ::
	@echo "  lint-helm            Syntax check helm charts"
ifdef VERBOSE
	@echo "  lint-helm COMPARISON_BRANCH=1    Local/dev lint (branch != master)"
endif
ifdef VERBOSE
	@echo "  lint-helm-deps       Configure dependent helm charts"
endif

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
