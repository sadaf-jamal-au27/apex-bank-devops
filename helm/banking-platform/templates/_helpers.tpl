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

{{- define "banking-platform.ingressPaths" -}}
- path: /v1
  pathType: Prefix
  backend:
    service:
      name: bff-api-service
      port:
        number: 8080
- path: /health
  pathType: Prefix
  backend:
    service:
      name: bff-api-service
      port:
        number: 8080
- path: /
  pathType: Prefix
  backend:
    service:
      name: {{ .Values.customerWeb.name }}
      port:
        number: {{ .Values.customerWeb.port }}
{{- end }}

{{- define "banking-platform.publicHostname" -}}
{{- if and .Values.gateway.enabled .Values.gateway.hostname -}}
{{- .Values.gateway.hostname -}}
{{- else -}}
{{- .Values.ingress.host -}}
{{- end -}}
{{- end }}

{{- define "banking-platform.publicAdminHostname" -}}
{{- if and .Values.gateway.enabled .Values.gateway.adminHostname -}}
{{- .Values.gateway.adminHostname -}}
{{- end -}}
{{- end }}

{{- define "banking-platform.bffPort" -}}
{{- $port := 8080 -}}
{{- range .Values.services -}}
{{- if eq .name "bff-api-service" -}}
{{- $port = .port -}}
{{- end -}}
{{- end -}}
{{- $port -}}
{{- end }}

{{- define "banking-platform.gatewayBffRules" -}}
{{- $bffPort := include "banking-platform.bffPort" . | int -}}
- matches:
    - path:
        type: PathPrefix
        value: {{ .Values.gateway.apiPrefix | default "/api" | quote }}
  filters:
    - type: URLRewrite
      urlRewrite:
        path:
          type: ReplacePrefixMatch
          replacePrefixMatch: {{ .Values.gateway.apiRewritePrefix | default "/v1" | quote }}
  backendRefs:
    - name: bff-api-service
      port: {{ $bffPort }}
- matches:
    - path:
        type: PathPrefix
        value: /v1
  backendRefs:
    - name: bff-api-service
      port: {{ $bffPort }}
- matches:
    - path:
        type: PathPrefix
        value: /health
  backendRefs:
    - name: bff-api-service
      port: {{ $bffPort }}
{{- end }}

{{- define "banking-platform.backendConfigSpec" -}}
healthCheck:
  checkIntervalSec: 15
  timeoutSec: 5
  healthyThreshold: 1
  unhealthyThreshold: 2
  type: HTTP
  requestPath: {{ .path | quote }}
  port: {{ .port }}
{{- end }}
