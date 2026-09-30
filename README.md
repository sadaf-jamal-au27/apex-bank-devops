# apex-bank-devops

Helm + GitHub Actions to deploy **apex-bank-app** onto the GCP landing zone from **apex-bank-infra**.

| Repo | Role |
|------|------|
| [apex-bank-infra](https://github.com/sadaf-jamal-au27/apex-bank-infra) | VPC, GKE, SQL, WIF, GAR |
| [apex-bank-app](https://github.com/sadaf-jamal-au27/apex-bank-app) | Microservices + image build/push |
| **apex-bank-devops** (this) | Kubernetes manifests (Helm), deploy pipelines |

## Dev target (from infra)

- Project: `ai-rag-agent-project`
- Cluster: `banking-dev` (`asia-south1`, **private endpoint**)
- Namespace / WI: `banking-dev` / K8s SA `banking-app` → GCP `banking-workload-dev@…`
- Images: `asia-south1-docker.pkg.dev/ai-rag-agent-project/banking/<service>:<tag>`
- DB: `postgres.sql.internal` (Cloud SQL PSC)

## Quick start (laptop — until VPC runner or Connect Gateway)

```bash
# 1) Infra outputs (from apex-bank-infra clone)
export PROJECT_ID=ai-rag-agent-project
export REGION=asia-south1
export CLUSTER=banking-dev

gcloud container clusters get-credentials "$CLUSTER" --region "$REGION" --project "$PROJECT_ID" --internal-ip

# 2) DB secret (password lives in Secret Manager)
./scripts/sync-db-secret.sh dev

# 3) Deploy
./scripts/deploy-dev.sh dev develop-latest
```

## CI

- **PR → develop/main:** `deploy-plan.yml` — `helm lint` + `helm template`
- **Push develop:** `deploy-dev.yml` prints a skip note (private cluster; no auto-deploy from GitHub-hosted runners)
- **workflow_dispatch:** `deploy-dev.yml` — `helm upgrade` when API is reachable (Connect Gateway / VPC runner; see [docs/DEPLOY.md](docs/DEPLOY.md))

Add **`apex-bank-devops`** to `github_repos` in infra `shared.tfvars` and re-apply `01-iam` so WIF trusts this repo.

Branching: [docs/BRANCHING.md](docs/BRANCHING.md)
