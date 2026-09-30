# Deploy to private GKE

The landing zone uses a **private control plane** (API often `172.16.x`). GitHub-hosted runners cannot call the master API unless one of these is true:

If CI fails with `dial tcp 172.16.x:443: i/o timeout` on `kubectl apply`, the runner has kubeconfig but **no network path** to the private endpoint — expected until one of the options below is in place.

| Option | When to use |
|--------|-------------|
| **Laptop + authorized network** | Your public IP in `master_authorized_cidrs`; `get-credentials --internal-ip` over VPN/corp |
| **Self-hosted runner in VPC** | Company standard — runner on GCE/GKE in `banking-dev-vpc` |
| **GKE Connect Gateway** | Register cluster to fleet; CI uses `use_connect_gateway: true` |

## What devops repo owns

1. **Helm chart** `helm/banking-platform` — namespace, WI SA, ConfigMap (DB host), Deployments/Services
2. **DB K8s secret** — `scripts/sync-db-secret.sh` reads GSM `banking-dev-sql-banking-app`
3. **Image tag** — default `develop-latest` from app CI push to GAR

Verify images after **apex-bank-app** CI push to `develop`:

```bash
gcloud artifacts docker images list \
  asia-south1-docker.pkg.dev/ai-rag-agent-project/banking \
  --include-tags --filter='tags:develop-latest'
```

## Infra handoff (terraform outputs)

| Output (stack) | Helm / deploy |
|----------------|---------------|
| `05-platform` `artifact_registry_url` | `global.imageRegistry` |
| `06-data` `dns_name` / `private_ip` | `global.database.host` → `postgres.sql.internal.` |
| `05-platform` `workload_service_account_email` | WI annotation on K8s SA |
| `05-platform` `k8s_workload_identity` | namespace + SA name |

## After first deploy

Run app SQL migrations (apex-bank-app) against Cloud SQL as `banking_app`.

Optional next: External Secrets Operator, Ingress + IAP for `bff-api-service`, Argo CD in this repo.
