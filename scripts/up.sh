#!/usr/bin/env bash
# Spin up the whole demo: cluster + app + public IP. Takes ~10-13 min.
# Images already live in Artifact Registry, so nothing is rebuilt here.
set -euo pipefail

ZONE=us-central1-a
CLUSTER=gke-app
HERE="$(cd "$(dirname "$0")" && pwd)"

echo ">> [1/4] Creating cluster '$CLUSTER' (2x e2-small, NAP off)... ~5-8 min"
gcloud container clusters create "$CLUSTER" \
  --zone "$ZONE" \
  --num-nodes 2 \
  --machine-type e2-small \
  --disk-size 30

echo ">> [2/4] Connecting kubectl to the cluster..."
gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE"

echo ">> [3/4] Deploying app (backend, frontend, services, HPAs)..."
kubectl apply -f "$HERE/../k8s/rendered-dev.yaml"
kubectl wait --for=condition=available --timeout=180s deployment --all -n gke-app

echo ">> [4/4] Waiting for the LoadBalancer external IP..."
IP=""
for i in $(seq 1 18); do
  IP="$(kubectl get svc frontend-service -n gke-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  [ -n "$IP" ] && break
  echo "   ...still pending ($i)"; sleep 10
done

echo
echo "============================================"
echo " READY  ->  http://${IP:-<still pending, run: kubectl get svc -n gke-app>}"
echo "============================================"
