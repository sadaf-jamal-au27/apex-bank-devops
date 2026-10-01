# Gateway API edge (banking-platform chart)

Legacy **`ingress.yaml`** (GCE Ingress + ManagedCertificate) is **disabled** when `gateway.enabled: true`.

## Files

| Template | Purpose |
|----------|---------|
| `gateway-api.yaml` | `Gateway` + shop/admin `HTTPRoute` |
| `healthcheck-gateway.yaml` | `HealthCheckPolicy` for BFF + customer-web |
| `ingress.yaml` | Legacy; only if `ingress.enabled: true` |

## Values (`values-dev.yaml`)

- `gateway.certMap` — from **apex-bank-infra** output (`banking-cert-map`)
- `gateway.staticIpName` — `banking-dev-portal-ip` (Terraform / gcloud)
- Hostnames: `dev-banking.beyondthecloud.in`, `dev-banking-admin.beyondthecloud.in`

## API paths

| Browser path | Backend |
|--------------|---------|
| `/` | customer-web |
| `/v1/*` | bff-api-service:8080 |
| `/api/*` | rewrite to `/v1/*` → BFF (retail-style) |
| `/health/*` | BFF |

Infra apply order: [EDGE_PORTAL.md](../../../../banking-infra/gke-banking-infra/docs/EDGE_PORTAL.md)
