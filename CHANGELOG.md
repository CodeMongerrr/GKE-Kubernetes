# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0](https://github.com/CodeMongerrr/GKE-Kubernetes/releases/tag/v1.0.0) - 2026-09-29

First tagged release. It packages the pipeline built in June 2026 together with a hardening and documentation pass.

### Added

- Two-tier Express app with `/version` endpoints that report the commit SHA baked into each image, covered by 10 Jest and Supertest tests
- Terraform for a zonal GKE cluster with an autoscaled node pool and Workload Identity
- Workload Identity Federation for GitHub Actions, so image pushes use short-lived credentials and no service account key exists
- Kustomize base with Deployments, Services, HorizontalPodAutoscalers and PodDisruptionBudgets, plus dev, prod and cd overlays
- Preferred pod anti-affinity, zero-surge rolling updates and a 120 second progress deadline on both Deployments
- A CI job that runs `terraform fmt -check` and `terraform validate` on every change to the infrastructure code
- GitHub Actions workflow with test, build-push and deploy jobs, and a post-deploy smoke test against the live LoadBalancer that rolls both Deployments back on failure
- Namespaced RBAC for the deploy identity, plus scripts for CD bootstrap and a quick gcloud demo cluster
- README with an architecture diagram, a deploy and teardown guide and cost notes
- MIT license and this changelog

### Changed

- Docs-only pushes no longer trigger the pipeline, and the workflow can be started by hand
- Build and deploy run only when the repository variable `CD_ENABLED` is `true`, so the pipeline stays green while no cluster is running
- Deploys never overlap, thanks to a concurrency group on the deploy job
- Workflow actions moved to their Node 24 majors, and tests run on Node 22
- Terraform enables the required Google APIs and creates the Artifact Registry repository
- The node pool uses `initial_node_count` so Terraform no longer fights the cluster autoscaler

### Fixed

- The smoke test could exit before rolling back if the LoadBalancer answered with a body that was not JSON
- `terraform destroy` failed because Google provider 5.x turns on cluster deletion protection by default

### Security

- The Workload Identity Federation provider only accepts tokens from the `main` branch
- The workflow token is limited to read access on repository contents
- Lockfiles updated to patched `qs` and `body-parser` releases, clearing three moderate npm advisories
