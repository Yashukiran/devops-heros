{{- define "tt.labels" -}}
app.kubernetes.io/part-of: task-tracker
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}
{{- define "tt.securityContext" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
runAsNonRoot: true
capabilities: { drop: ["ALL"] }
{{- end }}
