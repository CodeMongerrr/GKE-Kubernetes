# GKE Kubernetes Application

A containerized application deployed on **Google Kubernetes Engine (GKE)** with a control plane node and worker nodes running frontend/backend containers.

## Architecture

```
GKE Cluster
├── Control Plane (managed by GKE)
└── Node Pool
    ├── Frontend Pods (React/Next.js)
    └── Backend Pods (Node.js/Express)
```

## Project Structure

```
GKE-Kubernetes/
├── frontend/              # Frontend application
├── backend/               # Backend API service
├── k8s/                   # Kubernetes manifests
│   ├── base/              # Base configurations
│   └── overlays/          # Environment-specific overrides
│       ├── dev/
│       └── prod/
├── infrastructure/
│   └── terraform/         # GCP/GKE infrastructure as code
└── .github/workflows/     # CI/CD pipelines
```

## Prerequisites

- Google Cloud SDK (`gcloud`)
- Docker
- kubectl
- Terraform (for infrastructure provisioning)

## Getting Started

1. **Set up GCP project:**
   ```bash
   gcloud config set project <YOUR_PROJECT_ID>
   gcloud services enable container.googleapis.com
   ```

2. **Provision GKE cluster:**
   ```bash
   cd infrastructure/terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Build and push containers** (first-time seeding only — afterwards CI's
   `build-push` job is the source of truth and pushes SHA + `:dev` tags on every
   push to `main`). Images go to **Artifact Registry** with the `:dev` tag the
   manifests in `k8s/overlays/` expect. On Apple Silicon, build for `linux/amd64`
   so the images run on GKE's amd64 nodes:
   ```bash
   AR=<REGION>-docker.pkg.dev/<PROJECT_ID>/gke-app
   gcloud auth configure-docker <REGION>-docker.pkg.dev
   docker build --platform linux/amd64 -t $AR/frontend:dev ./frontend
   docker build --platform linux/amd64 -t $AR/backend:dev  ./backend
   docker push $AR/frontend:dev
   docker push $AR/backend:dev
   ```

4. **Deploy to GKE:**
   ```bash
   kubectl apply -k k8s/overlays/dev/
   ```

## CI/CD

Every push to `main` runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml) through three sequential jobs:

1. **test** — `npm test` for backend and frontend (also runs on pull requests).
2. **build-push** — builds a fresh image from the pushed source for each service and
   pushes it to Artifact Registry, tagged with the **commit SHA** (`${{ github.sha }}`)
   and a moving `dev` tag. The commit is baked into the image (`--build-arg GIT_SHA`).
3. **deploy** — rewrites the CD overlay's image tag to that commit SHA
   (`kustomize edit set image …`), then `kubectl apply -k k8s/overlays/cd` and waits
   for the rollout.

Because the deployed image tag changes on every commit, `kubectl apply` sees a real
PodSpec diff and triggers a genuine rolling update — the running workload actually
changes. Confirm which build is live by hitting the version endpoints:

```bash
# from inside the cluster / via the frontend LoadBalancer
curl http://<frontend-ip>/version     # frontend build commit
curl http://<frontend-ip>/api         # includes frontendCommit + backend.commit
```

The reported `commit` should match the SHA you just pushed.

### One-time setup

**Kubernetes API access** (the `deploy` job authenticates as a namespaced
ServiceAccount — no gcloud): run [`scripts/cd-bootstrap.sh`](scripts/cd-bootstrap.sh)
with admin `kubectl` access. It sets the `K8S_SERVER`, `K8S_CA`, `K8S_TOKEN` repo
**secrets**. Re-run it after every cluster recreate (the endpoint/CA/token change).

**Artifact Registry push access** (the `build-push` job authenticates via Workload
Identity Federation — no stored key):

```bash
cd infrastructure/terraform
terraform apply \
  -var="project_id=<PROJECT_ID>" \
  -var="github_repository=<owner>/<repo>"
```

Then set the two outputs as GitHub Actions repository **variables**
(Settings → Secrets and variables → Actions → *Variables*):

| GitHub Actions variable          | Terraform output                     |
| -------------------------------- | ------------------------------------ |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `github_workload_identity_provider`  |
| `GCP_DEPLOY_SA`                  | `github_deployer_sa_email`           |
