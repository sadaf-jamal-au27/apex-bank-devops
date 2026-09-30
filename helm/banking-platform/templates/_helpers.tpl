{{- define "banking-platform.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "banking-platform.fullname" -}}
{{- printf "%s-%s" (include "banking-platform.name" .) .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "banking-platform.labels" -}}
app.kubernetes.io/name: {{ include "banking-platform.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
banking.env: {{ .Values.global.env }}
{{- end }}

{{- define "banking-platform.image" -}}
{{- $svc := .svc -}}
{{- printf "%s/%s:%s" $.Values.global.imageRegistry $svc.name $.Values.global.imageTag }}
{{- end }}
