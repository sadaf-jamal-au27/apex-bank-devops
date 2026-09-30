# Branching (same as infra / app)

```text
feature/<name>  ──PR──►  develop  ──PR──►  main
                     │
                     ├─ PR: helm lint + template render
                     └─ merge to develop: deploy to GKE dev (when cluster access configured)
```

Environment **`dev`** secrets (GitHub): `GCP_WIF_PROVIDER`, `GCP_CI_SERVICE_ACCOUNT`, `GCP_PROJECT_ID` (optional, default in chart).
