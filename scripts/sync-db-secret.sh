#!/usr/bin/env bash
# Sync Cloud SQL app password from Secret Manager into the cluster.
set -euo pipefail

ENV="${1:-dev}"
PROJECT="${GCP_PROJECT_ID:-ai-rag-agent-project}"
NAMESPACE="${K8S_NAMESPACE:-banking-dev}"
SECRET_NAME="banking-db-credentials"
GSM_SECRET="banking-${ENV}-sql-banking-app"

command -v gcloud >/dev/null
command -v kubectl >/dev/null

PW="$(gcloud secrets versions access latest --secret="${GSM_SECRET}" --project="${PROJECT}")"

if ! kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
  echo "Namespace ${NAMESPACE} does not exist. Run helm upgrade first (deploy-dev.sh)." >&2
  exit 1
fi

kubectl create secret generic "${SECRET_NAME}" \
  --namespace="${NAMESPACE}" \
  --from-literal=password="${PW}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secret ${SECRET_NAME} updated in namespace ${NAMESPACE}"
