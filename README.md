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

3. **Build and push containers:**
   ```bash
   docker build -t gcr.io/<PROJECT_ID>/frontend:latest ./frontend
   docker build -t gcr.io/<PROJECT_ID>/backend:latest ./backend
   docker push gcr.io/<PROJECT_ID>/frontend:latest
   docker push gcr.io/<PROJECT_ID>/backend:latest
   ```

4. **Deploy to GKE:**
   ```bash
   kubectl apply -k k8s/overlays/dev/
   ```
