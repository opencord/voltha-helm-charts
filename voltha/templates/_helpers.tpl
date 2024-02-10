# Copyright 2020-2024 Open Networking Foundation (ONF) and the ONF Contributors
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
{{/* Expand the name of the chart. */}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{/* Create a default fully qualified app name. We truncate at 63 chars because . . . */}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- $fullname := default (printf "%s-%s" .Release.Name $name) .Values.fullNameOverride -}}
{{- $fullname | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{/* Create a default fully qualified virtual hostname. We truncate at 63 chars because . . . */}}
{{- define "virtual-hostname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- $fullname := default (print .Values.global.stack_name "." $name "." .Values.ingress.baseHostname) .Values.fullHostnameOverride -}}
{{- $fullname | trunc 63 | trimSuffix "-" -}}
{{- end -}}
