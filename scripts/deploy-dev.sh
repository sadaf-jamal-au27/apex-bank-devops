#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
IMAGE_TAG="${2:-develop-latest}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHART="${ROOT}/helm/banking-platform"
RELEASE="banking-platform"

helm lint "${CHART}"
"${ROOT}/scripts/sync-db-secret.sh" "${ENV}"

helm upgrade --install "${RELEASE}" "${CHART}" \
  --namespace banking-dev \
  --create-namespace \
  --set global.env="${ENV}" \
  --set global.imageTag="${IMAGE_TAG}" \
  --wait --timeout 15m

kubectl get deploy,svc -n banking-dev
