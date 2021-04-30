# Copyright 2020-present Open Networking Foundation
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
{{/* Create a list of controllers for of-agent starting from the number of ONOS Instances and the first openflow port */}}
{{- define "onosControllers" -}}
{{- $onosReplicas := default .Values.onos_classic.replicas 1 -}}
{{- $onosOfPort := default .Values.onos_classic.onosOfPort 6653 -}}
{{- $infraName := default .Values.global.voltha_infra_name "voltha-infra" -}}
{{- $infraNamespaces := default .Values.global.voltha_infra_namespace "infra" -}}
{{- $controllers := dict "controllers" (list) -}}
{{range $i, $e := until ($onosReplicas | int)}}
  {{- $port := add $onosOfPort $i -}}
  {{- $current := printf "--controller=%s-onos-classic-hs.%s.svc:%d" $infraName $infraNamespaces $port -}}
  {{- $controllers := (mustAppend $controllers.controllers $current) | set $controllers "controllers" -}}
{{end}}
{{- $controllers.controllers | join " " | quote -}}
{{- end -}}
