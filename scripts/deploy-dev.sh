#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
IMAGE_TAG="${2:-develop-latest}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHART="${ROOT}/helm/banking-platform"
RELEASE="banking-platform"

helm lint "${CHART}"

HELM_SET=(--namespace banking-dev --create-namespace
  --set "global.env=${ENV}"
  --set "global.imageTag=${IMAGE_TAG}")

# Namespace must be owned by Helm (chart template). DB secret is applied after NS exists.
helm upgrade --install "${RELEASE}" "${CHART}" \
  "${HELM_SET[@]}" \
  --wait=false --timeout 15m

"${ROOT}/scripts/sync-db-secret.sh" "${ENV}"

helm upgrade --install "${RELEASE}" "${CHART}" \
  "${HELM_SET[@]}" \
  --wait --timeout 15m

kubectl get deploy,svc -n banking-dev
