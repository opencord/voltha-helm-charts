# -*- makefile -*-
# -----------------------------------------------------------------------
# Copyright 2023-2024 Open Networking Foundation (ONF) and the ONF Contributors
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

##-------------------##
##---]  TARGETS  [---##
##-------------------##
.PHONY: lint-helmrepo

ifndef NO-LINT-HELMREPO
  lint : lint-helmrepo
endif

## -----------------------------------------------------------------------
## Intent: Jenkins hook test
## -----------------------------------------------------------------------
lint-helmrepo-deps += cord-charts-repo
lint-helmrepo-deps += lint-helm
lint-helmrepo: $(lint-helmrepo-deps)
	$(HIDE) $(MAKE) helm-repo-tools
	helm-repo-tools/helmrepo.sh --no-publish

## -----------------------------------------------------------------------
## Intent: Dependency for lint-helmrepo
## -----------------------------------------------------------------------
cord-charts-repo:
	git clone ssh://gerrit.opencord.org:29418/cord-charts-repo.git

## -----------------------------------------------------------------------
## Intent: Checkout lint tools
## -----------------------------------------------------------------------
helm-repo-tools:
	git clone "https://gerrit.opencord.org/helm-repo-tools"

## -----------------------------------------------------------------------
## Intent: Revert to a pristine sandbox checkout
## ----------------------------------------------------------------------
sterile ::
	$(RM) -r cord-charts-repo
	$(RM) -r helm-repo-tools

# [EOF]
