{{- define "metrics-app.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "metrics-app.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "metrics-app.serviceAccountName" -}}
{{ if .Values.serviceAccount.name }}{{ .Values.serviceAccount.name }}{{ else }}{{ include "metrics-app.fullname" . }}{{ end }}
{{- end }}

{{- define "metrics-app.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "metrics-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "metrics-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "metrics-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
