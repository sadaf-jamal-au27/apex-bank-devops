# GitHub Environment `dev`

Same WIF pool as infra/app (after adding this repo to infra `github_repos`):

| Secret | Value |
|--------|--------|
| `GCP_WIF_PROVIDER` | From infra `01-iam` output `wif_provider` |
| `GCP_CI_SERVICE_ACCOUNT` | `github-ci-banking-dev@ai-rag-agent-project.iam.gserviceaccount.com` |

Optional: `GCP_PROJECT_ID` if not using chart default.

**Private GKE:** hosted runners need **Connect Gateway** or deploy from laptop — see [docs/DEPLOY.md](../docs/DEPLOY.md).
