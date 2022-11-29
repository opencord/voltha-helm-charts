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
# -----------------------------------------------------------------------

##-------------------##
##---]  GLOBALS  [---##
##-------------------##
env-clean     = /usr/bin/env --ignore-environment
xargs-n1      := xargs -0 -t -n1 --no-run-if-empty

helmlint-sh   := $(TOP)/helm-repo-tools/helmlint.sh
chartcheck-sh := $(TOP)/helm-repo-tools/chart_version_check.sh

##-------------------##
##---]  TARGETS  [---##
##-------------------##
.PHONY: lint-helm
.PHONY: lint-chart

ifdef UNSTABLE
  # Repair failures before enabling as a default.
  lint : lint-helm
  lint : lint-chart
endif

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
lint-helm: $(helmlint-sh)
	$(helmlint-sh)

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
lint-chart: $(chartcheck-sh)
	$(chartcheck-sh)

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
$(helmlint-sh) $(chartcheck-sh):
	git clone "https://gerrit.opencord.org/helm-repo-tools"

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
help::
	@echo "  lint-chart                    chart_version_check.sh"
	@echo "  lint-helm                     Syntax check helm configs"

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
clean::
	$(RM) -r $(TOP)/helm-repo-tools

# [EOF]
