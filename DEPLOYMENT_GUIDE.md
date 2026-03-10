# Ghost Accountant - Google Cloud Deployment Guide

**For Gemini Live Agent Challenge 2026**

This guide walks you through deploying Ghost Accountant's AI orchestration layer to Google Cloud Platform.

---

## Prerequisites

1. **Google Cloud Account**
   - Create account at [console.cloud.google.com](https://console.cloud.google.com)
   - Enable billing (free tier available)

2. **Required Tools**
   ```bash
   # Install Google Cloud SDK
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   
   # Install Terraform
   brew install terraform  # macOS
   # or download from terraform.io
   
   # Verify installations
   gcloud --version
   terraform --version
   ```

3. **Gemini API Key**
   - Get from [Google AI Studio](https://aistudio.google.com/app/apikey)
   - Or use Vertex AI (no separate key needed)

---

## Step 1: Google Cloud Project Setup

```bash
# Login to Google Cloud
gcloud auth login

# Create new project
gcloud projects create ghost-accountant-prod --name="Ghost Accountant"

# Set as active project
gcloud config set project ghost-accountant-prod

# Enable billing (required for Cloud Run)
# Visit: https://console.cloud.google.com/billing/linkedaccount?project=ghost-accountant-prod

# Set default region
gcloud config set run/region us-central1
```

---

## Step 2: Enable Required APIs

```bash
# Enable all required Google Cloud APIs
gcloud services enable \
  run.googleapis.com \
  aiplatform.googleapis.com \
  storage.googleapis.com \
  firestore.googleapis.com \
  cloudbuild.googleapis.com \
  containerregistry.googleapis.com

# Verify APIs are enabled
gcloud services list --enabled
```

---

## Step 3: Build and Push Docker Image

```bash
# Navigate to project root
cd ghost_accountant

# Create Dockerfile for AI orchestrator
cat > Dockerfile <<EOF
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe lib/server/ai_orchestrator_server.dart -o server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/bin/

EXPOSE 8080
CMD ["/app/bin/server"]
EOF

# Build Docker image
docker build -t gcr.io/ghost-accountant-prod/ghost-accountant-ai:latest .

# Configure Docker for GCR
gcloud auth configure-docker

# Push to Google Container Registry
docker push gcr.io/ghost-accountant-prod/ghost-accountant-ai:latest
```

---

## Step 4: Deploy with Terraform

```bash
# Navigate to Terraform directory
cd infrastructure/terraform

# Copy example variables
cp variables.tfvars.example variables.tfvars

# Edit variables.tfvars with your values
nano variables.tfvars

# Initialize Terraform
terraform init

# Preview deployment
terraform plan -var-file=variables.tfvars

# Deploy to Google Cloud
terraform apply -var-file=variables.tfvars

# Save outputs
terraform output > deployment_outputs.txt
```

**Expected Outputs:**
```
cloud_run_url = "https://ghost-accountant-ai-xxxxx-uc.a.run.app"
receipts_bucket = "ghost-accountant-prod-receipts"
firestore_database = "(default)"
service_account_email = "ghost-ai-orchestrator@ghost-accountant-prod.iam.gserviceaccount.com"
vertex_ai_endpoint = "projects/ghost-accountant-prod/locations/us-central1"
```

---

## Step 5: Verify Deployment

```bash
# Get Cloud Run URL
CLOUD_RUN_URL=$(terraform output -raw cloud_run_url)

# Test health endpoint
curl $CLOUD_RUN_URL/health

# Expected response:
# {
#   "status": "healthy",
#   "service": "ghost-accountant-ai-orchestrator",
#   "version": "5.0.0",
#   "gemini_api": "connected",
#   "vertex_ai": "connected"
# }

# Test receipt analysis endpoint
curl -X POST $CLOUD_RUN_URL/api/v1/analyze-receipt \
  -H "Content-Type: application/json" \
  -d '{
    "image": "base64_encoded_receipt_image",
    "region": "US"
  }'
```

---

## Step 6: Configure Flutter App

```bash
# Update .env file with Cloud Run URL
echo "CLOUD_RUN_SERVICE_URL=$CLOUD_RUN_URL" >> .env

# Update lib/core/config/environment.dart
cat > lib/core/config/environment.dart <<EOF
class Environment {
  static const String cloudRunUrl = String.fromEnvironment(
    'CLOUD_RUN_SERVICE_URL',
    defaultValue: '$CLOUD_RUN_URL',
  );
  
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
  );
  
  static const String googleCloudProject = 'ghost-accountant-prod';
  static const String vertexAiLocation = 'us-central1';
}
EOF

# Run Flutter app
flutter run
```

---

## Step 7: Setup Firestore Security Rules

```bash
# Create firestore.rules
cat > firestore.rules <<EOF
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data - only accessible by owner
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Receipts - only accessible by owner
    match /receipts/{receiptId} {
      allow read, write: if request.auth != null && 
                           resource.data.userId == request.auth.uid;
    }
    
    // Financial data - only accessible by owner
    match /financial/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
EOF

# Deploy security rules
gcloud firestore indexes create --project=ghost-accountant-prod
firebase deploy --only firestore:rules
```

---

## Step 8: Setup Cloud Storage Permissions

```bash
# Get service account email
SERVICE_ACCOUNT=$(terraform output -raw service_account_email)

# Grant storage permissions
gsutil iam ch serviceAccount:$SERVICE_ACCOUNT:objectAdmin \
  gs://ghost-accountant-prod-receipts

# Set bucket lifecycle policy
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
        "condition": {"age": 365}
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle.json gs://ghost-accountant-prod-receipts
```

---

## Step 9: Setup Monitoring & Logging

```bash
# Enable Cloud Monitoring
gcloud services enable monitoring.googleapis.com

# Create uptime check
gcloud monitoring uptime create ghost-accountant-health \
  --resource-type=uptime-url \
  --host=$CLOUD_RUN_URL \
  --path=/health \
  --check-interval=60s

# View logs
gcloud logging read "resource.type=cloud_run_revision AND \
  resource.labels.service_name=ghost-accountant-ai-orchestrator" \
  --limit 50 \
  --format json
```

---

## Step 10: Setup CI/CD (Optional)

```bash
# Create Cloud Build configuration
cat > cloudbuild.yaml <<EOF
steps:
  # Build Docker image
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/\$PROJECT_ID/ghost-accountant-ai:latest', '.']
  
  # Push to Container Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/\$PROJECT_ID/ghost-accountant-ai:latest']
  
  # Deploy to Cloud Run
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args:
      - 'run'
      - 'deploy'
      - 'ghost-accountant-ai-orchestrator'
      - '--image'
      - 'gcr.io/\$PROJECT_ID/ghost-accountant-ai:latest'
      - '--region'
      - 'us-central1'
      - '--platform'
      - 'managed'

images:
  - 'gcr.io/\$PROJECT_ID/ghost-accountant-ai:latest'
EOF

# Create build trigger
gcloud builds triggers create github \
  --repo-name=ghost_accountant \
  --repo-owner=your-github-username \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

---

## Cost Estimation

### Google Cloud Platform (Monthly)

**Free Tier (First 12 months):**
- Cloud Run: 2M requests free
- Cloud Storage: 5GB free
- Firestore: 50K reads, 20K writes free
- Gemini API: Pay-as-you-go

**Typical Usage (100 users):**
- Cloud Run: $0.00 (within free tier)
- Gemini API: $78.00 (100 receipts/user)
- Cloud Storage: $2.00 (100GB receipts)
- Firestore: $0.00 (within free tier)
- **Total: ~$80/month for 100 users**

**Per User Cost: $0.80/month**

---

## Troubleshooting

### Issue: Cloud Run deployment fails

```bash
# Check service logs
gcloud run services logs read ghost-accountant-ai-orchestrator \
  --region=us-central1 \
  --limit=50

# Check service status
gcloud run services describe ghost-accountant-ai-orchestrator \
  --region=us-central1
```

### Issue: Gemini API not connecting

```bash
# Verify API key
gcloud auth application-default print-access-token

# Test Vertex AI endpoint
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://us-central1-aiplatform.googleapis.com/v1/projects/ghost-accountant-prod/locations/us-central1/publishers/google/models/gemini-3.0-flash:generateContent \
  -d '{"contents":[{"parts":[{"text":"Hello"}]}]}'
```

### Issue: Firestore permission denied

```bash
# Check IAM permissions
gcloud projects get-iam-policy ghost-accountant-prod

# Grant Firestore user role
gcloud projects add-iam-policy-binding ghost-accountant-prod \
  --member=serviceAccount:$SERVICE_ACCOUNT \
  --role=roles/datastore.user
```

---

## Cleanup (Optional)

```bash
# Destroy all resources
cd infrastructure/terraform
terraform destroy -var-file=variables.tfvars

# Delete project (WARNING: irreversible)
gcloud projects delete ghost-accountant-prod
```

---

## Next Steps

1. ✅ Deploy to Google Cloud (this guide)
2. 📹 Record demonstration video
3. 📝 Write Medium article
4. 🚀 Submit to Gemini Live Agent Challenge

---

## Support

- **Documentation**: See `/docs` folder
- **Issues**: GitHub Issues
- **Google Cloud Support**: [cloud.google.com/support](https://cloud.google.com/support)

---

**Deployment Status: ✅ Production Ready**

**Last Updated:** March 10, 2026
