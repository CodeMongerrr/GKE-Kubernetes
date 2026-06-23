# Workload Identity Federation for GitHub Actions.
#
# This lets the CI workflow push images to Artifact Registry WITHOUT a stored
# service-account key: GitHub mints a short-lived OIDC token, GCP trusts it via
# this pool/provider, and the workflow impersonates the deployer service account
# for a few minutes only.
#
# NOTE: the Artifact Registry repository itself ("gke-app") is assumed to already
# exist (created at cluster bootstrap). This file only grants push access to it.
# To have Terraform manage the repo too, add a google_artifact_registry_repository
# resource and `terraform import` the existing one first.

# The GCP service account the GitHub workflow impersonates.
resource "google_service_account" "github_deployer" {
  account_id   = "github-deployer"
  display_name = "GitHub Actions image pusher"
  project      = var.project_id
}

# Let the deployer SA push (and pull) images in the app's Artifact Registry repo.
resource "google_artifact_registry_repository_iam_member" "deployer_writer" {
  project    = var.project_id
  location   = var.ar_location
  repository = var.ar_repository
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.github_deployer.email}"
}

# Identity pool that holds external (GitHub) identities.
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
  description               = "OIDC identities from GitHub Actions"
}

# Provider that trusts GitHub's OIDC issuer. The attribute_condition restricts
# token exchange to THIS repository — without it, any GitHub repo could assume
# the identity.
resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow workflows from this repo to impersonate the deployer SA.
resource "google_service_account_iam_member" "github_wif" {
  service_account_id = google_service_account.github_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}
