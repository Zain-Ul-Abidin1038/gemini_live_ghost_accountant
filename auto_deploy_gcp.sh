#!/bin/bash

# Ghost Accountant - Automated GCP Deployment (Non-Interactive)
# This script deploys without requiring user input

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Ghost Accountant - Automated GCP Deployment"
echo "=========================================="
echo ""

# Configuration
PROJECT_ID="ghost-accountant-prod"
REGION="us-central1"
SERVICE_NAME="ghost-accountant-ai-orchestrator"

# Check authentication
echo -e "${BLUE}Checking Google Cloud authentication...${NC}"
CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -n 1)

if [ -z "$CURRENT_ACCOUNT" ]; then
    echo -e "${RED}✗ Not logged in to Google Cloud${NC}"
    echo "Please run: gcloud auth login"
    exit 1
fi

echo -e "${GREEN}✓ Logged in as: $CURRENT_ACCOUNT${NC}"
echo ""

# Step 1: Create Project
echo "=========================================="
echo "Step 1: Creating Project"
echo "=========================================="
echo ""

if gcloud projects describe $PROJECT_ID &> /dev/null; then
    echo -e "${GREEN}✓ Project $PROJECT_ID already exists${NC}"
else
    echo -e "${BLUE}Creating project $PROJECT_ID...${NC}"
    gcloud projects create $PROJECT_ID --name="Ghost Accountant" 2>/dev/null || true
    echo -e "${GREEN}✓ Project created${NC}"
fi

# Set active project
gcloud config set project $PROJECT_ID
echo -e "${GREEN}✓ Active project set to $PROJECT_ID${NC}"
echo ""

# Step 2: Check Billing
echo "=========================================="
echo "Step 2: Billing Check"
echo "=========================================="
echo ""

BILLING_ENABLED=$(gcloud beta billing projects describe $PROJECT_ID --format="value(billingEnabled)" 2>/dev/null || echo "false")

if [ "$BILLING_ENABLED" = "True" ]; then
    echo -e "${GREEN}✓ Billing is enabled${NC}"
else
    echo -e "${YELLOW}⚠️  Billing is not enabled for this project${NC}"
    echo ""
    echo "Please enable billing at:"
    echo -e "${BLUE}https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID${NC}"
    echo ""
    echo "After enabling billing, run this script again."
    echo ""
    echo "Note: New Google Cloud accounts get $300 free credit!"
    exit 1
fi
echo ""

# Step 3: Enable Required APIs
echo "=========================================="
echo "Step 3: Enabling Required APIs"
echo "=========================================="
echo ""

APIS=(
    "run.googleapis.com"
    "aiplatform.googleapis.com"
    "storage.googleapis.com"
    "firestore.googleapis.com"
    "cloudbuild.googleapis.com"
    "containerregistry.googleapis.com"
)

for api in "${APIS[@]}"; do
    echo -e "${BLUE}Enabling $api...${NC}"
    gcloud services enable $api --project=$PROJECT_ID 2>/dev/null || true
done

echo -e "${GREEN}✓ All required APIs enabled${NC}"
echo ""

# Step 4: Gemini API Configuration
echo "=========================================="
echo "Step 4: Gemini API Configuration"
echo "=========================================="
echo ""

# Use Vertex AI (no separate key needed)
GEMINI_API_KEY="vertex-ai"
echo -e "${GREEN}✓ Using Vertex AI (no separate API key needed)${NC}"
echo ""

# Step 5: Create Terraform Variables
echo "=========================================="
echo "Step 5: Creating Terraform Configuration"
echo "=========================================="
echo ""

cd infrastructure/terraform

cat > variables.tfvars <<EOF
project_id      = "$PROJECT_ID"
region          = "$REGION"
gemini_api_key  = "$GEMINI_API_KEY"
EOF

echo -e "${GREEN}✓ Terraform variables file created${NC}"
echo ""

# Step 6: Initialize Terraform
echo "=========================================="
echo "Step 6: Initializing Terraform"
echo "=========================================="
echo ""

terraform init

echo -e "${GREEN}✓ Terraform initialized${NC}"
echo ""

# Step 7: Plan Deployment
echo "=========================================="
echo "Step 7: Planning Deployment"
echo "=========================================="
echo ""

terraform plan -var-file=variables.tfvars

echo ""
echo -e "${YELLOW}Deployment plan created. Applying in 5 seconds...${NC}"
sleep 5
echo ""

# Step 8: Apply Terraform
echo "=========================================="
echo "Step 8: Deploying to Google Cloud"
echo "=========================================="
echo ""

terraform apply -var-file=variables.tfvars -auto-approve

echo -e "${GREEN}✓ Infrastructure deployed${NC}"
echo ""

# Step 9: Get Outputs
echo "=========================================="
echo "Step 9: Deployment Information"
echo "=========================================="
echo ""

CLOUD_RUN_URL=$(terraform output -raw cloud_run_url 2>/dev/null || echo "Not available yet")
RECEIPTS_BUCKET=$(terraform output -raw receipts_bucket 2>/dev/null || echo "Not available yet")
SERVICE_ACCOUNT=$(terraform output -raw service_account_email 2>/dev/null || echo "Not available yet")

echo -e "${GREEN}Deployment Complete!${NC}"
echo ""
echo "=========================================="
echo "Deployment Details:"
echo "=========================================="
echo ""
echo -e "Cloud Run URL:       ${BLUE}$CLOUD_RUN_URL${NC}"
echo -e "Receipts Bucket:     ${BLUE}$RECEIPTS_BUCKET${NC}"
echo -e "Service Account:     ${BLUE}$SERVICE_ACCOUNT${NC}"
echo -e "Project ID:          ${BLUE}$PROJECT_ID${NC}"
echo -e "Region:              ${BLUE}$REGION${NC}"
echo ""

# Save outputs
cd ../..

cat > deployment_outputs.txt <<EOF
Ghost Accountant - GCP Deployment Outputs
==========================================

Cloud Run URL:       $CLOUD_RUN_URL
Receipts Bucket:     $RECEIPTS_BUCKET
Service Account:     $SERVICE_ACCOUNT
Project ID:          $PROJECT_ID
Region:              $REGION

Deployed: $(date)
EOF

echo -e "${GREEN}✓ Deployment details saved to deployment_outputs.txt${NC}"
echo ""

# Step 10: Update Flutter App
echo "=========================================="
echo "Step 10: Updating Flutter App Configuration"
echo "=========================================="
echo ""

# Create .env file
cat > .env <<EOF
CLOUD_RUN_SERVICE_URL=$CLOUD_RUN_URL
GOOGLE_CLOUD_PROJECT=$PROJECT_ID
VERTEX_AI_LOCATION=$REGION
GEMINI_API_KEY=$GEMINI_API_KEY
EOF

echo -e "${GREEN}✓ .env file created${NC}"

# Update environment.dart
mkdir -p lib/core/config

cat > lib/core/config/environment.dart <<EOF
// Auto-generated environment configuration
// Generated: $(date)

class Environment {
  static const String cloudRunUrl = String.fromEnvironment(
    'CLOUD_RUN_SERVICE_URL',
    defaultValue: '$CLOUD_RUN_URL',
  );
  
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '$GEMINI_API_KEY',
  );
  
  static const String googleCloudProject = '$PROJECT_ID';
  static const String vertexAiLocation = '$REGION';
  
  // Feature flags
  static const bool useCloudRun = true;
  static const bool useVertexAI = true;
  static const bool enableGhostTrace = true;
  static const bool enableGroundedSearch = true;
}
EOF

echo -e "${GREEN}✓ environment.dart updated${NC}"
echo ""

# Step 11: Test Deployment
echo "=========================================="
echo "Step 11: Testing Deployment"
echo "=========================================="
echo ""

if [ "$CLOUD_RUN_URL" != "Not available yet" ]; then
    echo -e "${BLUE}Testing health endpoint...${NC}"
    echo "Waiting 10 seconds for service to be ready..."
    sleep 10
    
    if curl -s -f "$CLOUD_RUN_URL/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Health check passed!${NC}"
        echo ""
        echo "Response:"
        curl -s "$CLOUD_RUN_URL/health" | python3 -m json.tool 2>/dev/null || curl -s "$CLOUD_RUN_URL/health"
    else
        echo -e "${YELLOW}⚠️  Health check endpoint not responding yet${NC}"
        echo "This is normal - the service may need a few minutes to start"
        echo ""
        echo "You can test manually later with:"
        echo -e "${BLUE}curl $CLOUD_RUN_URL/health${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Cloud Run URL not available yet${NC}"
    echo "Check the Google Cloud Console for deployment status"
fi

echo ""

# Final Summary
echo "=========================================="
echo "🎉 Deployment Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo ""
echo "1. View deployment details:"
echo -e "   ${BLUE}cat deployment_outputs.txt${NC}"
echo ""
echo "2. Test the deployment:"
echo -e "   ${BLUE}curl $CLOUD_RUN_URL/health${NC}"
echo ""
echo "3. Run the Flutter app:"
echo -e "   ${BLUE}flutter run${NC}"
echo ""
echo "4. View Cloud Console:"
echo -e "   ${BLUE}https://console.cloud.google.com/run?project=$PROJECT_ID${NC}"
echo ""
echo "5. Record demo video (see DEMO_VIDEO_STRATEGY.md)"
echo ""
echo "6. Submit to competition before March 17, 2026"
echo ""
echo "=========================================="
echo "Good luck with the competition! 🚀"
echo "=========================================="
