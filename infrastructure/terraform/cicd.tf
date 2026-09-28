# Workload Identity Federation for GitHub Actions.
#
# This lets the CI workflow push images to Artifact Registry WITHOUT a stored
# service-account key: GitHub mints a short-lived OIDC token, GCP trusts it via
# this pool/provider, and the workflow impersonates the deployer service account
# for a few minutes only.
#
# The Artifact Registry repository is created here when create_ar_repository is
# true (the default for a fresh project). If the repo already exists, either set
# create_ar_repository = false or `terraform import` it into
# google_artifact_registry_repository.app[0] first.

resource "google_artifact_registry_repository" "app" {
  count = var.create_ar_repository ? 1 : 0

  project       = var.project_id
  location      = var.ar_location
  repository_id = var.ar_repository
  format        = "DOCKER"
  description   = "Container images for the GKE demo app"

  depends_on = [google_project_service.required]
}

locals {
  ar_repository_name = var.create_ar_repository ? google_artifact_registry_repository.app[0].repository_id : var.ar_repository
}

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
  repository = local.ar_repository_name
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
# token exchange to THIS repository and to its main branch, so a workflow on a
# feature branch or a pull request cannot mint push credentials.
resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}' && assertion.ref == 'refs/heads/main'"

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
