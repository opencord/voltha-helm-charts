# -*- makefile -*-
# -----------------------------------------------------------------------
# Copyright 2022-2023 Open Networking Foundation (ONF) and the ONF Contributors
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
helmlint-sh   := $(TOP)/helm-repo-tools/helmlint.sh
chartcheck-sh := $(TOP)/helm-repo-tools/chart_version_check.sh

##-------------------##
##---]  TARGETS  [---##
##-------------------##

## -----------------------------------------------------------------------
## Intent: repo:helm-repo-tools
##   o Use script as a dependency for on-demand cloning.
##   o Use of repo name (r-h-t) as a dependency is problematic.
## -----------------------------------------------------------------------
$(helmlint-sh) $(chartcheck-sh):
	git clone "https://gerrit.opencord.org/helm-repo-tools"

## -----------------------------------------------------------------------
## Intent: Remove generated targets
## -----------------------------------------------------------------------
clean ::
	$(chartcheck-sh) clean

## -----------------------------------------------------------------------
## -----------------------------------------------------------------------
sterile::
	$(RM) -r $(TOP)/helm-repo-tools

# [EOF]
