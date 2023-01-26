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
# Intent: Define for includers
#    o get-git-branch
#    - lint-helm-branch   -- clean this up, generic set by USE_LEGACY=undef
# -----------------------------------------------------------------------

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
# USE_LEGACY = 1
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

# [EOF]
