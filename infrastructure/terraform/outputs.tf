output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.primary.endpoint
  sensitive = true
}

output "cluster_location" {
  value = google_container_cluster.primary.location
}

# Set these two as GitHub Actions repository VARIABLES (Settings -> Secrets and
# variables -> Actions -> Variables): they are consumed by the build-push job as
# vars.GCP_WORKLOAD_IDENTITY_PROVIDER and vars.GCP_DEPLOY_SA. They are not secret.
output "github_workload_identity_provider" {
  description = "-> GitHub Actions variable GCP_WORKLOAD_IDENTITY_PROVIDER"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_deployer_sa_email" {
  description = "-> GitHub Actions variable GCP_DEPLOY_SA"
  value       = google_service_account.github_deployer.email
}
