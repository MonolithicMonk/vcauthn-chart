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



{{/* Check if a given value is a map */}}
{{- define "isMap" -}}
  {{- if kindIs "map" . }}
    {{- true }}
  {{- else }}
    {{- false }}
  {{- end }}
{{- end -}}

{{/* Check if a given value is a slice */}}
{{- define "isSlice" -}}
  {{- if kindIs "slice" . }}
    {{- true }}
  {{- else }}
    {{- false }}
  {{- end }}
{{- end -}}

{{/*
generate environment variables for vc configuration
*/}}

{{- define "generateEnvVars" -}}
{{- range $key, $value := .Values.configuration }}
  # Do if first level value is map / list
  {{- if kindIs "slice" $value }}
    {{- range $subkey, $subvalue := $value }}
      # Do if 2nd level value is slice / list
      {{- if kindIs "slice" $subvalue }}
        {{- range $subsubkey, $subsubvalue := $subvalue }}
          # Do if 3rd level value is slice / list
          {{- if kindIs "slice" $subsubvalue }}
            {{- range $subsubsubkey, $subsubsubvalue := $subsubvalue }}
              # Do if 4th level value is slice / list
              {{- if kindIs "slice" $subsubsubvalue }}
                {{- range $subsubsubsubkey, $subsubsubsubvalue := $subsubsubvalue }}
                  # Do if 4th level value isn't a slice / list
                  {{- $envVarSubSubSubSubName := printf "%s__%s__%s__%s__%s" (title $key) (title $subkey) (title $subsubsubkey) (title $subsubsubsubkey) -}}
                  {{- $envVarSubSubSubSubValue := quote $subsubsubsubvalue -}}
                  - name: {{ $envVarSubSubSubSubName }}
                    value: {{ $envVarSubSubSubSubValue }}
                {{- end  }}
              {{- else }}
                # Do if 4th level value isn't a map / list
                {{- $envVarSubSubSubName := printf "%s__%s__%s__%s" (title $key) (title $subkey) (title $subsubsubkey) -}}
                {{- $envVarSubSubSubValue := quote $subsubsubvalue -}}
                - name: {{ $envVarSubSubSubName }}
                  value: {{ $envVarSubSubSubValue }}
              {{- end }}
            {{- end }}
          {{- else }}
            # Do if 3rd level value isn't a map / list
            {{- $envVarSubSubName := printf "%s__%s__%s" (title $key) (title $subkey) (title $subsubkey) -}}
            {{- $envVarSubSubValue := quote $subsubvalue -}}
            - name: {{ $envVarSubSubName }}
              value: {{ $envVarSubSubValue }}
          {{- end }}
        {{- end }}
      {{- else }}
        # Do if 2nd level value isn't a map / list
        {{- $envVarSubName := printf "%s__%s" (title $key) (title $subkey) -}}
        {{- $envVarSubValue := quote $subvalue -}}
        - name: {{ $envVarSubName }}
          value: {{ $envVarSubValue }}
      {{- end }}
    {{- end }}    
  {{- else }}
    # Do if 1st level value isn't map / list
    {{- $envVarName := printf "%s" (title $key) -}}
    {{- $envVarValue := quote $value -}}
    - name: {{ $envVarName }}
      value: {{ $envVarValue }}
  {{- end }}
{{- end -}}
{{- end -}}

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