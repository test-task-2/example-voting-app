{{- define "voting-lib.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "voting-lib.fullname" -}}
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

{{- define "voting-lib.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "voting-lib.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "voting-lib.selectorLabels" -}}
app.kubernetes.io/name: {{ include "voting-lib.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "voting-lib.image" -}}
{{- $tag := default "latest" .tag | toString }}
{{- printf "%s:%s" .repository $tag }}
{{- end }}

{{- define "voting-lib.db" -}}
{{- $global := default dict .Values.global }}
{{- default dict $global.db | toYaml }}
{{- end }}

{{- define "voting-lib.redis" -}}
{{- $global := default dict .Values.global }}
{{- default dict $global.redis | toYaml }}
{{- end }}

{{- define "voting-lib.postgresSecretName" -}}
{{- $db := include "voting-lib.db" . | fromYaml }}
{{- default (printf "%s-postgres" .Release.Name) $db.secretName }}
{{- end }}

{{- define "voting-lib.redisSecretName" -}}
{{- $redis := include "voting-lib.redis" . | fromYaml }}
{{- default (printf "%s-redis" .Release.Name) $redis.secretName }}
{{- end }}

{{- define "voting-lib.dbEnabled" -}}
{{- $db := include "voting-lib.db" . | fromYaml }}
{{- if hasKey $db "enabled" }}
{{- $db.enabled }}
{{- else }}
{{- true }}
{{- end }}
{{- end }}

{{- define "voting-lib.redisEnabled" -}}
{{- $redis := include "voting-lib.redis" . | fromYaml }}
{{- if hasKey $redis "enabled" }}
{{- $redis.enabled }}
{{- else }}
{{- true }}
{{- end }}
{{- end }}

{{- define "voting-lib.postgresEnv" -}}
{{- $db := include "voting-lib.db" . | fromYaml }}
{{- $secret := include "voting-lib.postgresSecretName" . }}
{{- if eq (include "voting-lib.dbEnabled" .) "true" }}
- name: POSTGRES_HOST
  value: {{ default "db" $db.host | quote }}
- name: POSTGRES_PORT
  value: {{ default "5432" $db.port | quote }}
{{- else if $db.connectionSecret }}
- name: POSTGRES_HOST
  valueFrom:
    secretKeyRef:
      name: {{ $db.connectionSecret }}
      key: host
- name: POSTGRES_PORT
  valueFrom:
    secretKeyRef:
      name: {{ $db.connectionSecret }}
      key: port
{{- else }}
- name: POSTGRES_HOST
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: host
- name: POSTGRES_PORT
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: port
{{- end }}
- name: POSTGRES_DB
  value: {{ default "postgres" $db.database | quote }}
- name: POSTGRES_USER
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: username
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: password
{{- end }}

{{- define "voting-lib.redisEnv" -}}
{{- $redis := include "voting-lib.redis" . | fromYaml }}
{{- $secret := include "voting-lib.redisSecretName" . }}
{{- if eq (include "voting-lib.redisEnabled" .) "true" }}
- name: REDIS_HOST
  value: {{ default "redis" $redis.host | quote }}
- name: REDIS_PORT
  value: {{ default "6379" $redis.port | quote }}
{{- else if $redis.connectionSecret }}
- name: REDIS_HOST
  valueFrom:
    secretKeyRef:
      name: {{ $redis.connectionSecret }}
      key: primary_endpoint_address
- name: REDIS_PORT
  valueFrom:
    secretKeyRef:
      name: {{ $redis.connectionSecret }}
      key: port
{{- else }}
- name: REDIS_HOST
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: host
- name: REDIS_PORT
  valueFrom:
    secretKeyRef:
      name: {{ $secret }}
      key: port
{{- end }}
{{- end }}

{{- define "voting-lib.gatewayProvider" -}}
{{- $global := default dict .Values.global }}
{{- $gateway := default dict $global.gateway }}
{{- default "traefik" $gateway.provider }}
{{- end }}

{{- define "voting-lib.parentRefs" -}}
{{- $global := default dict .Values.global }}
{{- $gateway := default dict $global.gateway }}
{{- toYaml (default list $gateway.parentRefs) }}
{{- end }}
