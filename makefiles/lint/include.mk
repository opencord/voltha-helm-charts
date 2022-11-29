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

# ------------------------------------------------
# On-demand loading:
#   - lint helm charts
#   - on demand for now, errors and cleanup needed
#   - Usage: make lint-helm USE_LEGACY=<blank>
# ------------------------------------------------
include $(MAKEDIR)/lint/helm.mk
include $(MAKEDIR)/lint/helm/include.mk

# ------------------------------------------------------------
## yaml checking
##   o yamllint - check everything, all the time.
##   o python   - dependency based checking
# ------------------------------------------------------------
ifdef YAML_FILES
  include $(MAKEDIR)/lint/yaml/python.mk
else
  include $(MAKEDIR)/lint/yaml/yamllint.mk
endif

# [EOF]
