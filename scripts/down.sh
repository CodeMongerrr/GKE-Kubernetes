#!/usr/bin/env bash
# Tear down the demo to stop billing. Deletes the cluster + its LoadBalancer.
# Artifact Registry images are KEPT (cost ~pennies/month) so the next up.sh is fast.
set -euo pipefail

ZONE=us-central1-a
CLUSTER=gke-app

echo ">> Deleting cluster '$CLUSTER' (also tears down the LoadBalancer)..."
gcloud container clusters delete "$CLUSTER" --zone "$ZONE" --quiet

echo ">> Done. Images remain in Artifact Registry. Run scripts/up.sh to bring it all back."
