{{/*
Expand the name of the chart.
*/}}
{{- define "vcauthn.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vcauthn.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "vcauthn.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vcauthn.labels" -}}
helm.sh/chart: {{ include "vcauthn.chart" . }}
{{ include "vcauthn.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vcauthn.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vcauthn.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vcauthn.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "vcauthn.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
generate hosts if not overriden
*/}}
{{- define "vcauthn.host" -}}
{{- if .Values.ingress.hosts -}}
{{- (index .Values.ingress.hosts 0).host -}}
{{- else }}
{{- include "vcauthn.fullname" . }}.{{ .Release.Namespace | default "default" }}.svc.cluster.local
{{- end -}}
{{- end }}

{{/*
generate environment variables for vc configuration
*/}}
{{- define "generateEnvVarsClients" -}}
{{- range $index, $key := .Values.configuration.identityServer.clients }}
	{{- $firstLevel := printf "%s__%s__%d" (title "identityServer") (title "clients") $index -}}
  {{- range $k, $v := $key }}
  {{- $secLevel := printf "%s__%s" $firstLevel ( title $k) }}
  {{- if kindIs "slice" $v  -}}
  	{{- range $k1, $v1 := $v}}
    	{{- $thirdLevel := printf "%s__%d" $secLevel $k1 }}
      {{- printf "\n- name: %s" $thirdLevel }}
      {{- printf "\n  value: %s" ($v1 | quote) }}
    {{- end }}
  {{- else }}
  	{{- printf "\n- name: %s" $secLevel }}
    {{- printf "\n  value: %s" ($v | quote) }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
generate environment variables for vc configuration
*/}}
{{- define "generateEnvVarsLogs" -}}
{{- range $key, $value := .Values.configuration.serilog }}
	{{- $firstLevel := printf "%s__%s" (title "serilog") (title $key) -}}
  {{- range $k, $v := $value }}
  {{- $secLevel := printf "%s__%s" $firstLevel $k }}
  	{{- if kindIs "map" $v  }}
    	{{- range $k1, $v1 := $v }}
        {{- if kindIs "int" $k }}
          {{- $seclev := printf "%s__%d" $firstLevel $k }}
          {{- $thirdLevel := printf "%s__%s" $seclev ( title $k1 ) }}
          {{- printf "\n- name: %s" $thirdLevel }}
          {{- printf "\n  value: %s" ($v1 | quote) }}
        {{- else }}
        	{{- $seclev := printf "%s__%s" $firstLevel ( title $k ) }}
          {{- $thirdLevel := printf "%s__%s" $seclev ( title $k1 ) }}
          {{- printf "\n- name: %s" $thirdLevel }}
          {{- printf "\n  value: %s" ($v1 | quote) }}
        {{- end }}
      {{- end }}
    {{- else }}
    		{{- if kindIs "int" $k }}
          {{- $seclev := printf "%s__%d" $firstLevel $k }}
          {{- printf "\n- name: %s" $seclev }}
          {{- printf "\n  value: %s" ($v | quote) }}
        {{- else }}
        	{{- $seclev := printf "%s__%s" $firstLevel ( title $k ) }}
          {{- printf "\n- name: %s" $seclev }}
          {{- printf "\n  value: %s" ($v | quote) }}
        {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}