resource "google_cloudbuild_trigger" "service-account-trigger" {
  source_to_build {
    uri       = "https://github.com/alizaidis/terraform-asm-multicluster"
    ref       = "refs/heads/issue-1"
    repo_type = "GITHUB"
  }
  build {
    timeout = "3600s"
    step {
      name = "gcr.io/kaniko-project/executor:v1.6.0"
      id = "build-installer-image"
      args = ["--destination=us-west1-docker.pkg.dev/${var.project_id}/platform-installer/installer", "--cache=true", "--cache-ttl=12h"]
      timeout = "120s"
    }
    step {
      name = "us-west1-docker.pkg.dev/${var.project_id}/platform-installer/installer"
      id = "gke-asm-terraform"
      dir = "asm"
      entrypoint = "bash"
      args = ["-xe", "-c", "echo \"project_id = ${var.project_id}\" > terraform.tfvars", "terraform init -backend-config=\"bucket=${var.project_id}-tfstate\"", "terraform plan -out terraform.tfplan", "terraform apply -input=false -lock=false terraform.tfplan"]
      timeout = "1200s"
    }
    options {
        worker_pool = "projects/${var.project_id}/workerPools/${google_cloudbuild_worker_pool.private-build-pool.name}"
        logging = "STACKDRIVER_ONLY"
    }
  }
  service_account = google_service_account.cloudbuild_service_account.id
  project = var.project_id
  depends_on = [
    google_project_iam_member.act_as,
    google_project_iam_member.logs_writer
  ]
}

resource "google_service_account" "cloudbuild_service_account" {
  account_id = "terraform-cloud-build"
  project = var.project_id
}

resource "google_project_iam_member" "act_as" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

resource "google_project_iam_member" "logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

resource "google_artifact_registry_repository" "platform-installer" {
  provider = google-beta

  location = var.region_1
  repository_id = "platform-installer"
  description = "Repo for platform installer container images built by Cloud Build."
  format = "DOCKER"
  depends_on = [time_sleep.wait_120_seconds, module.enabled_google_apis]
}

resource "google_artifact_registry_repository_iam_member" "cloud-build-member" {
  provider = google-beta

  location = google_artifact_registry_repository.platform-installer.location
  repository = google_artifact_registry_repository.platform-installer.name
  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}