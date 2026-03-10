# Ghost Accountant - Google Cloud Infrastructure
# Terraform configuration for Gemini Live Agent Challenge

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud Region"
  type        = string
  default     = "us-central1"
}

variable "gemini_api_key" {
  description = "Gemini API Key"
  type        = string
  sensitive   = true
}

# Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable Required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "aiplatform.googleapis.com",
    "storage.googleapis.com",
    "firestore.googleapis.com",
    "cloudbuild.googleapis.com",
  ])
  
  service            = each.value
  disable_on_destroy = false
}

# Cloud Storage Bucket for Receipts
resource "google_storage_bucket" "receipts" {
  name     = "${var.project_id}-receipts"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  encryption {
    default_kms_key_name = null
  }
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}

# Cloud Storage Bucket for AI Model Cache
resource "google_storage_bucket" "models" {
  name     = "${var.project_id}-models"
  location = var.region
  
  uniform_bucket_level_access = true
}

# Firestore Database
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"
  
  depends_on = [google_project_service.required_apis]
}

# Service Account for Cloud Run
resource "google_service_account" "ai_orchestrator" {
  account_id   = "ghost-ai-orchestrator"
  display_name = "Ghost Accountant AI Orchestrator"
  description  = "Service account for AI orchestration on Cloud Run"
}

# IAM Roles for Service Account
resource "google_project_iam_member" "ai_orchestrator_roles" {
  for_each = toset([
    "roles/aiplatform.user",
    "roles/storage.objectAdmin",
    "roles/datastore.user",
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.ai_orchestrator.email}"
}

# Cloud Run Service - AI Orchestrator
resource "google_cloud_run_service" "ai_orchestrator" {
  name     = "ghost-accountant-ai-orchestrator"
  location = var.region
  
  template {
    spec {
      service_account_name = google_service_account.ai_orchestrator.email
      
      containers {
        image = "gcr.io/${var.project_id}/ghost-accountant-ai:latest"
        
        resources {
          limits = {
            cpu    = "2000m"
            memory = "2Gi"
          }
        }
        
        env {
          name  = "GEMINI_API_KEY"
          value = var.gemini_api_key
        }
        
        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }
        
        env {
          name  = "VERTEX_AI_LOCATION"
          value = var.region
        }
        
        env {
          name  = "FIRESTORE_DATABASE"
          value = "(default)"
        }
        
        env {
          name  = "CLOUD_STORAGE_BUCKET"
          value = google_storage_bucket.receipts.name
        }
        
        ports {
          container_port = 8080
        }
      }
      
      container_concurrency = 80
      timeout_seconds       = 300
    }
    
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale" = "0"
        "autoscaling.knative.dev/maxScale" = "100"
      }
    }
  }
  
  traffic {
    percent         = 100
    latest_revision = true
  }
  
  depends_on = [google_project_service.required_apis]
}

# Allow unauthenticated access (for demo purposes)
# In production, use authenticated access
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.ai_orchestrator.name
  location = google_cloud_run_service.ai_orchestrator.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Outputs
output "cloud_run_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_service.ai_orchestrator.status[0].url
}

output "receipts_bucket" {
  description = "Cloud Storage bucket for receipts"
  value       = google_storage_bucket.receipts.name
}

output "firestore_database" {
  description = "Firestore database name"
  value       = google_firestore_database.database.name
}

output "service_account_email" {
  description = "Service account email"
  value       = google_service_account.ai_orchestrator.email
}

output "vertex_ai_endpoint" {
  description = "Vertex AI endpoint"
  value       = "projects/${var.project_id}/locations/${var.region}"
}
