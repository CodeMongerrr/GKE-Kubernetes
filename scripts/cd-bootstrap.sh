#!/usr/bin/env bash
# One-time (per cluster) setup for GitHub Actions CD.
# Run this with your ADMIN kubectl access while the cluster is UP.
#
# It: (1) creates the github-deployer ServiceAccount + RBAC + token,
#     (2) reads the cluster API endpoint + CA from your current kubeconfig,
#     (3) uploads K8S_SERVER / K8S_CA / K8S_TOKEN as GitHub repo secrets.
#
# NOTE: the cluster endpoint, CA, and token all CHANGE when you delete and
# recreate the cluster (scripts/down.sh + up.sh). Re-run this script after
# every recreate to refresh the secrets, or CD will fail to connect.
set -euo pipefail

NS=gke-app
HERE="$(cd "$(dirname "$0")" && pwd)"

echo ">> [1/4] Creating ServiceAccount + RBAC + token..."
kubectl apply -f "$HERE/../k8s/cd-rbac.yaml"

echo ">> [2/4] Waiting for the token to be populated..."
for i in $(seq 1 15); do
  TOKEN="$(kubectl get secret github-deployer-token -n "$NS" -o jsonpath='{.data.token}' 2>/dev/null || true)"
  [ -n "$TOKEN" ] && break
  sleep 2
done
[ -n "${TOKEN:-}" ] || { echo "ERROR: token never populated"; exit 1; }
TOKEN="$(echo "$TOKEN" | base64 -d)"

echo ">> [3/4] Reading cluster endpoint + CA from current kubeconfig..."
SERVER="$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.server}')"
CA="$(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')"
[ -n "$SERVER" ] && [ -n "$CA" ] || { echo "ERROR: could not read server/CA"; exit 1; }

echo ">> [4/4] Uploading GitHub repo secrets (via gh)..."
gh secret set K8S_SERVER --body "$SERVER"
gh secret set K8S_CA     --body "$CA"
gh secret set K8S_TOKEN  --body "$TOKEN"

echo
echo "Done. Secrets set: K8S_SERVER, K8S_CA, K8S_TOKEN"
echo "Server: $SERVER"
echo "Push to main (or merge the PR) to trigger a deploy."
