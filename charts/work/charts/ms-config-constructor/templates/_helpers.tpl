{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Universal labels list
*/}}
{{- define "helpers.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
app.kubernetes.io/managed-by: "Helm"
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/component: {{ .Values.component | quote  }}
app.kubernetes.io/part-of: {{ .Values.global.project | quote  }}
app.kubernetes.io/created-by: {{ .Values.maintainer | quote  }}
project: {{ .Values.global.project | quote }}
version: {{ .Values.image.tag | quote }}
contour: {{ .Values.global.contour | quote }}
{{- end }}

{{/*
Universal selector labels list
*/}}
{{- define "helpers.matchLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
project: {{ .Values.global.project }}
contour: {{ .Values.global.contour }}
{{- end }}

{{/*
Universal annotations list
deploymentTime used for recreate pods even if app and chart versions not changed
*/}}
{{- define "helpers.annotations" -}}
deploymentTime: {{ now | date "2006-01-02T15:04:05" }}
{{- end }}