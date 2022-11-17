# -*- makefile -*-
# -----------------------------------------------------------------------
# Copyright 2022 Open Networking Foundation (ONF) and the ONF Contributors
# -----------------------------------------------------------------------

ifdef YAML_FILES
  include $(MAKEDIR)/lint/yaml/python.mk
else
  include $(MAKEDIR)/lint/yaml/yamllint.mk
endif

# [EOF]
