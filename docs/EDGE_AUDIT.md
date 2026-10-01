# Public edge: Load Balancer, endpoints, audit & full user flow

This doc ties together **infra**, **Helm**, **app CI**, and **what auditors expect** so customers can use the banking portal on the internet end-to-end.

## 1. Connection map (full path)

```text
User browser (https://bank.example.com)
    │
    ▼
Global HTTP(S) Load Balancer  ← created by GKE Ingress (GCE class)
    │  • Static global IP (Terraform, named)
    │  • ManagedCertificate (HTTPS)
    │  • Cloud Armor (Terraform, prod)
    │  • Access logs → Logging/BigQuery
    │
    ├─ path /        → Service customer-web:80   (React UI, nginx)
    ├─ path /v1/*    → Service bff-api-service:8080
    └─ path /health/*→ Service bff-api-service:8080
              │
              ▼
    BFF → identity-service:3001, account-service:3002, … (ClusterIP only)
              │
              ▼
    Cloud SQL postgres.sql.internal (PSC, private)
```

**Audit rule:** Only **customer-web** and **bff-api-service** are public backends. No other Service type LoadBalancer.

## 2. Repos & ownership

| Repo | Owns |
|------|------|
| **apex-bank-app** | Code, Docker images → GAR (`customer-web`, `bff-api-service`, …) |
| **apex-bank-devops** | Helm: Deployments, Ingress, BackendConfig, ManagedCertificate |
| **apex-bank-infra** | VPC, private GKE, SQL, WIF, **static IP**, DNS zone, Cloud Armor, IAM |

## 3. Setup order (greenfield)

### Phase A — Platform (once)

1. **apex-bank-infra** applied: GKE private, GAR repo `banking`, SQL, WI, VPC-SC.
2. Node SA (or custom GKE node SA): `roles/artifactregistry.reader` on repo `banking`.
3. Terraform (recommended for audit):

```bash
gcloud compute addresses create banking-dev-portal-ip --global --project=ai-rag-agent-project
# Optional: Cloud DNS managed zone + A record → that IP
# Optional: google_compute_security_policy (Cloud Armor) attached to backend service later
```

### Phase B — Images (every release)

1. Merge **apex-bank-app** → `develop` → CI pushes `develop-latest` for all images including **customer-web**.

### Phase C — Cluster app + internal wiring

```bash
# DB secret (once per env)
PW=$(gcloud secrets versions access latest --secret=banking-dev-sql-banking-app --project=ai-rag-agent-project)
kubectl create secret generic banking-db-credentials -n banking-dev \
  --from-literal=password="$PW" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install banking-platform helm/banking-platform -n banking-dev \
  --create-namespace \
  --set global.imageTag=develop-latest \
  --set customerWeb.enabled=true \
  --wait --timeout 20m
```

ConfigMap must include `IDENTITY_URL`, `ACCOUNT_URL`, … so BFF works in-cluster.

Run **DB migrations** from app repo against Cloud SQL (first time).

### Phase D — Public edge (Ingress = Load Balancer)

**Dev demo (HTTP, ephemeral IP):**

```bash
helm upgrade banking-platform helm/banking-platform -n banking-dev \
  --reuse-values \
  --set ingress.enabled=true \
  --set ingress.host= \
  --set ingress.managedCertificate=false \
  --wait --timeout 25m

kubectl get ingress -n banking-dev -w
# User: http://<ADDRESS>/
```

**Audit / staging / prod (HTTPS + fixed IP + domain):**

```bash
helm upgrade banking-platform helm/banking-platform -n banking-dev \
  --reuse-values \
  --set ingress.enabled=true \
  --set ingress.host=banking.yourdomain.com \
  --set ingress.staticIpName=banking-dev-portal-ip \
  --set ingress.managedCertificate=true \
  --wait --timeout 25m
```

Wait for ManagedCertificate **Active** (15–60 min). Users: **`https://banking.yourdomain.com`**.

### Phase E — Verify backends (functional + audit evidence)

```bash
kubectl describe ingress -n banking-dev | grep -A5 backends
# bff-api-service: HEALTHY, customer-web: HEALTHY

curl -sI "http://<IP-or-host>/"
curl -s "http://<IP-or-host>/v1/bff/info"
```

Register/login in browser (customer-web → same host `/v1/...`).

## 4. BackendConfig (why BFF was UNHEALTHY)

GCE LB default health check is `GET /` on the backend port. BFF returns 404 on `/`; use **BackendConfig** with `requestPath: /health/live` and annotate the Service:

`cloud.google.com/backend-config: '{"default": "bff-api-service"}'`

Helm creates this when `ingress.enabled=true` and `bff-api-service.public: true`.

## 5. Audit checklist (evidence to keep)

| Control | Evidence |
|---------|----------|
| Least exposure | Ingress manifest; only 2 public backends; describe ingress |
| Encryption in transit | ManagedCertificate status; TLS test (ssllabs / `curl -vI https://…`) |
| Change control | Git PR + Helm revision (`helm history`) |
| Identity / IAM | WIF for CI; no long-lived keys in GitHub |
| Logging | LB logging enabled; sink to BigQuery; sample query |
| WAF (prod) | Cloud Armor policy name + rules export |
| DR / naming | Static IP name in Terraform state |
| Data | SQL private IP/PSC; no DB in Ingress |

## 6. User-facing endpoints (document for support)

| URL | Consumer use |
|-----|----------------|
| `https://<host>/` | Banking portal (register, login, accounts) |
| `https://<host>/v1/banking/...` | API (used by UI; mobile apps same base URL) |
| `https://<host>/health/live` | Ops monitoring (restrict in prod via Armor/path) |

## 7. Common failures

| Symptom | Fix |
|---------|-----|
| `Not Found` on `/` | Use **http** if no cert; wait for LB; refresh when backends HEALTHY |
| 502 on `/v1` | BFF UNHEALTHY → BackendConfig + rollout; check BFF logs |
| Login fails | Migrations; DB secret; BFF `IDENTITY_URL` |
| ImagePullBackOff | Node SA `artifactregistry.reader` on GAR |

See also: [PUBLIC_ACCESS.md](./PUBLIC_ACCESS.md), [DEPLOY.md](./DEPLOY.md).
