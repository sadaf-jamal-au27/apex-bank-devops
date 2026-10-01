# Public banking portal (internet users)

End customers use **one HTTPS URL** in the browser. The load balancer sends:

| Path | Backend |
|------|---------|
| `/` | **customer-web** (React banking UI) |
| `/v1`, `/health` | **bff-api-service** (APIs) |

Microservices stay **ClusterIP** (not on the public internet).

## Prerequisites

1. Backend already deployed (`helm upgrade banking-platform …`).
2. **customer-web** image in GAR (`customer-web:develop-latest`) — push from **apex-bank-app** CI after merge.
3. Node SA can pull GAR (`roles/artifactregistry.reader` on repo `banking`).

## Option A — Quick demo (HTTP, Load Balancer IP only)

No custom domain. Users open `http://<EXTERNAL_IP>/`.

```bash
helm upgrade --install banking-platform helm/banking-platform \
  -n banking-dev \
  --set global.imageTag=develop-latest \
  --set customerWeb.enabled=true \
  --set ingress.enabled=true \
  --set ingress.host= \
  --set ingress.managedCertificate=false \
  --wait --timeout 20m

kubectl get ingress -n banking-dev -w
# ADDRESS column → give users http://ADDRESS/
```

## Option B — Real bank URL (HTTPS + domain)

1. Reserve a **global static IP**:

```bash
gcloud compute addresses create banking-dev-portal-ip --global --project=ai-rag-agent-project
gcloud compute addresses describe banking-dev-portal-ip --global --format='get(address)'
```

2. DNS (banking-only subdomains): `dev-banking.beyondthecloud.in` and `dev-banking-admin.beyondthecloud.in` → `136.81.139.205` (do not reuse retail `dev-shop` / `dev-admin`).

3. Deploy:

```bash
helm upgrade --install banking-platform helm/banking-platform \
  -n banking-dev \
  --set global.imageTag=develop-latest \
  --set customerWeb.enabled=true \
  --set ingress.enabled=true \
  --set ingress.host=banking.yourdomain.com \
  --set ingress.staticIpName=banking-dev-portal-ip \
  --set ingress.managedCertificate=true \
  --wait --timeout 20m
```

4. **DNS must point at the load balancer IP before HTTPS can work.** Google checks that each hostname resolves to the same IP as the Ingress (`136.81.139.205` for dev).

```bash
dig +short dev-banking.beyondthecloud.in A
# must return 136.81.139.205
```

5. Wait 15–60 minutes after DNS is correct for **ManagedCertificate** → `Active`. Then the load balancer gets **443** (not only port 80):

```bash
kubectl get managedcertificate -n banking-dev
gcloud compute forwarding-rules list --global --filter="IPAddress=136.81.139.205" --format='table(name,portRange)'
# expect 80-80 and 443-443
curl -sI https://dev-banking.beyondthecloud.in/
```

6. Customer opens: `https://dev-banking.beyondthecloud.in` (HTTP redirects to HTTPS when `ingress.redirectToHttps` is true).

## After upgrade (BFF in-cluster URLs)

ConfigMap sets `IDENTITY_URL`, `ACCOUNT_URL`, etc. Redeploy once so BFF picks them up:

```bash
helm upgrade banking-platform helm/banking-platform -n banking-dev --reuse-values --wait
```

## Production extras (later)

- **Cloud Armor** WAF, rate limits
- **IAP** for admin paths
- **Cloud CDN** for static UI
- Separate mobile apps → same BFF URL
