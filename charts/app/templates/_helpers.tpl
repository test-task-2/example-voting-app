{{- define "app.hostname" -}}
{{- if .Values.httpRoute.hostname }}
{{- .Values.httpRoute.hostname }}
{{- else }}
{{- $global := default dict .Values.global }}
{{- $domains := default dict $global.domains }}
{{- index $domains (include "voting-lib.name" .) | default "" }}
{{- end }}
{{- end }}

{{- define "app.parentRefs" -}}
{{- if .Values.httpRoute.parentRefs }}
{{- toYaml .Values.httpRoute.parentRefs }}
{{- else }}
{{- include "voting-lib.parentRefs" . }}
{{- end }}
{{- end }}

{{- define "app.imagePullSecrets" -}}
{{- $global := default dict .Values.global }}
{{- $secrets := .Values.imagePullSecrets | default list }}
{{- if $secrets }}
{{- toYaml $secrets }}
{{- else if $global.imagePullSecrets }}
{{- toYaml $global.imagePullSecrets }}
{{- end }}
{{- end }}

{{- define "app.podTemplate" -}}
metadata:
  labels:
    {{- include "voting-lib.selectorLabels" . | nindent 4 }}
  {{- if .Values.configMap.enabled }}
  annotations:
    checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
  {{- end }}
spec:
  {{- with include "app.imagePullSecrets" . }}
  imagePullSecrets:
    {{- . | nindent 4 }}
  {{- end }}
  containers:
    - name: {{ include "voting-lib.name" . }}
      image: {{ include "voting-lib.image" .Values.image }}
      imagePullPolicy: {{ .Values.image.pullPolicy }}
      {{- if and .Values.configMap.enabled .Values.configMap.command }}
      command:
        {{- toYaml .Values.configMap.command | nindent 8 }}
      {{- end }}
      {{- if and .Values.configMap.enabled .Values.configMap.args }}
      args:
        {{- toYaml .Values.configMap.args | nindent 8 }}
      {{- end }}
      {{- if or .Values.service.enabled .Values.containerPort }}
      ports:
        - name: {{ .Values.portName }}
          containerPort: {{ .Values.containerPort }}
          protocol: TCP
      {{- end }}
      env:
        {{- if .Values.env.postgres }}
        {{- include "voting-lib.postgresEnv" . | nindent 8 }}
        {{- end }}
        {{- if .Values.env.redis }}
        {{- include "voting-lib.redisEnv" . | nindent 8 }}
        {{- end }}
        {{- with .Values.extraEnv }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      {{- if and .Values.configMap.enabled .Values.configMap.env }}
      envFrom:
        - configMapRef:
            name: {{ include "voting-lib.fullname" . }}
      {{- end }}
      {{- if and .Values.configMap.enabled .Values.configMap.mountPath .Values.configMap.data }}
      volumeMounts:
        - name: web-config
          mountPath: {{ .Values.configMap.mountPath }}
          readOnly: true
      {{- end }}
      {{- with .Values.resources }}
      resources:
        {{- toYaml . | nindent 8 }}
      {{- end }}
  {{- if .Values.podAntiAffinity }}
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              {{- include "voting-lib.selectorLabels" . | nindent 14 }}
          topologyKey: kubernetes.io/hostname
  {{- end }}
  {{- with .Values.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if and .Values.configMap.enabled .Values.configMap.mountPath .Values.configMap.data }}
  volumes:
    - name: web-config
      configMap:
        name: {{ include "voting-lib.fullname" . }}
  {{- end }}
{{- end }}
