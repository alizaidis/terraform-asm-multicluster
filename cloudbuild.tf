resource "google_cloudbuild_trigger" "service-account-trigger" {
  source_to_build {
    uri       = "https://github.com/alizaidis/terraform-asm-multicluster"
    ref       = "refs/heads/issue-1"
    repo_type = "GITHUB"
  }
  service_account = google_service_account.cloudbuild_service_account.id
  project = var.project_id
  filename        = "cloudbuild.yaml"
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
}

resource "google_artifact_registry_repository_iam_member" "cloud-build-member" {
  provider = google-beta

  location = google_artifact_registry_repository.platform-installer.location
  repository = google_artifact_registry_repository.platform-installer.name
  role   = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}