terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# APIs the stack needs. disable_on_destroy = false so a teardown never turns
# off an API that something else in the project still uses.
resource "google_project_service" "required" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  # Provider 5.x defaults this to true, which makes `terraform destroy` fail.
  # Off by default here because this is a demo stack that should be cheap to
  # tear down. Set it to true for anything long lived.
  deletion_protection = var.deletion_protection

  # Remove default node pool after creation
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = "default"
  subnetwork = "default"

  # Enable Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  depends_on = [google_project_service.required]
}

# Node pool for application workloads
resource "google_container_node_pool" "app_nodes" {
  name     = "app-node-pool"
  location = var.zone
  cluster  = google_container_cluster.primary.name

  # initial_node_count (not node_count) so Terraform does not fight the
  # cluster autoscaler over the live node count on every plan.
  initial_node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    disk_size_gb = 50

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env = var.environment
    }
  }

  autoscaling {
    min_node_count = 1
    max_node_count = var.max_node_count
  }
}
