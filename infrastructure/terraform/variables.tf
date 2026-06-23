variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "gke-app-cluster"
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 5
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-medium"
}

variable "environment" {
  description = "Environment label (dev/prod)"
  type        = string
  default     = "dev"
}

# --- CI/CD (GitHub Actions -> Artifact Registry via Workload Identity Federation) ---

variable "github_repository" {
  description = "GitHub repo allowed to push images, as owner/name (e.g. CodeMongerrr/GKE-Kubernetes)"
  type        = string
}

variable "ar_location" {
  description = "Artifact Registry location (must match the image paths in k8s overlays)"
  type        = string
  default     = "asia-southeast1"
}

variable "ar_repository" {
  description = "Artifact Registry repository name that holds the app images"
  type        = string
  default     = "gke-app"
}
