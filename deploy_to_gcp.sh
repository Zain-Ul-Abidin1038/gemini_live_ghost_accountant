#!/bin/bash

# Ghost Accountant - GCP Deployment Script
# Automated deployment to Google Cloud Platform

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Ghost Accountant - GCP Deployment"
echo "=========================================="
echo ""

# Configuration
PROJECT_ID="ghost-accountant-prod"
REGION="us-central1"
SERVICE_NAME="ghost-accountant-ai-orchestrator"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}✗ gcloud not found. Please run ./setup_gcp_tools.sh first${NC}"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}✗ terraform not found. Please run ./setup_gcp_tools.sh first${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All required tools are installed${NC}"
echo ""

# Step 1: Login to Google Cloud
echo "=========================================="
echo "Step 1: Google Cloud Authentication"
echo "=========================================="
echo ""

# Check if already logged in
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    echo -e "${GREEN}✓ Already logged in as: $CURRENT_ACCOUNT${NC}"
    echo ""
    read -p "Do you want to use this account? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Logging in to Google Cloud...${NC}"
        gcloud auth login
    fi
else
    echo -e "${BLUE}Logging in to Google Cloud...${NC}"
    gcloud auth login
fi

echo ""

# Step 2: Create or Select Project
echo "=========================================="
echo "Step 2: Project Setup"
echo "=========================================="
echo ""

# Check if project exists
if gcloud projects describe $PROJECT_ID &> /dev/null; then
    echo -e "${GREEN}✓ Project $PROJECT_ID already exists${NC}"
else
    echo -e "${YELLOW}Project $PROJECT_ID does not exist${NC}"
    read -p "Create new project? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Creating project $PROJECT_ID...${NC}"
        gcloud projects create $PROJECT_ID --name="Ghost Accountant"
        echo -e "${GREEN}✓ Project created${NC}"
    else
        echo -e "${YELLOW}Please enter your existing project ID:${NC}"
        read -p "Project ID: " PROJECT_ID
    fi
fi

# Set active project
echo -e "${BLUE}Setting active project to $PROJECT_ID...${NC}"
gcloud config set project $PROJECT_ID
echo -e "${GREEN}✓ Active project set${NC}"

echo ""

# Step 3: Enable Billing
echo "=========================================="
echo "Step 3: Billing Check"
echo "=========================================="
echo ""

echo -e "${YELLOW}⚠️  Billing must be enabled for this project${NC}"
echo "Please ensure billing is enabled at:"
echo -e "${BLUE}https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID${NC}"
echo ""
read -p "Press Enter when billing is enabled..."

echo ""

# Step 4: Enable Required APIs
echo "=========================================="
echo "Step 4: Enabling Required APIs"
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
    gcloud services enable $api --project=$PROJECT_ID
done

echo -e "${GREEN}✓ All required APIs enabled${NC}"
echo ""

# Step 5: Get Gemini API Key
echo "=========================================="
echo "Step 5: Gemini API Configuration"
echo "=========================================="
echo ""

echo "You need a Gemini API key from Google AI Studio"
echo -e "${BLUE}https://aistudio.google.com/app/apikey${NC}"
echo ""
echo "Or you can use Vertex AI (no separate key needed)"
echo ""
read -p "Do you have a Gemini API key? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter your Gemini API key: " GEMINI_API_KEY
else
    echo -e "${YELLOW}Using Vertex AI (no separate key needed)${NC}"
    GEMINI_API_KEY="vertex-ai"
fi

echo ""

# Step 6: Create Terraform Variables File
echo "=========================================="
echo "Step 6: Creating Terraform Configuration"
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

# Step 7: Initialize Terraform
echo "=========================================="
echo "Step 7: Initializing Terraform"
echo "=========================================="
echo ""

terraform init

echo -e "${GREEN}✓ Terraform initialized${NC}"
echo ""

# Step 8: Plan Deployment
echo "=========================================="
echo "Step 8: Planning Deployment"
echo "=========================================="
echo ""

terraform plan -var-file=variables.tfvars

echo ""
read -p "Review the plan above. Continue with deployment? (y/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

echo ""

# Step 9: Apply Terraform
echo "=========================================="
echo "Step 9: Deploying to Google Cloud"
echo "=========================================="
echo ""

terraform apply -var-file=variables.tfvars -auto-approve

echo -e "${GREEN}✓ Infrastructure deployed${NC}"
echo ""

# Step 10: Get Outputs
echo "=========================================="
echo "Step 10: Deployment Information"
echo "=========================================="
echo ""

CLOUD_RUN_URL=$(terraform output -raw cloud_run_url)
RECEIPTS_BUCKET=$(terraform output -raw receipts_bucket)
SERVICE_ACCOUNT=$(terraform output -raw service_account_email)

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

# Save outputs to file
cat > ../../deployment_outputs.txt <<EOF
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

# Step 11: Test Deployment
echo "=========================================="
echo "Step 11: Testing Deployment"
echo "=========================================="
echo ""

echo -e "${BLUE}Testing health endpoint...${NC}"

# Wait a few seconds for service to be ready
sleep 5

if curl -s -f "$CLOUD_RUN_URL/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Health check passed!${NC}"
    echo ""
    echo "Response:"
    curl -s "$CLOUD_RUN_URL/health" | python3 -m json.tool || curl -s "$CLOUD_RUN_URL/health"
else
    echo -e "${YELLOW}⚠️  Health check endpoint not responding yet${NC}"
    echo "This is normal - the service may need a few minutes to start"
    echo "You can test manually later with:"
    echo -e "${BLUE}curl $CLOUD_RUN_URL/health${NC}"
fi

echo ""

# Step 12: Update Flutter App Configuration
echo "=========================================="
echo "Step 12: Updating Flutter App"
echo "=========================================="
echo ""

cd ../..

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

# Final Summary
echo "=========================================="
echo "🎉 Deployment Successful!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo ""
echo "1. Test the deployment:"
echo -e "   ${BLUE}curl $CLOUD_RUN_URL/health${NC}"
echo ""
echo "2. Run the Flutter app:"
echo -e "   ${BLUE}flutter run${NC}"
echo ""
echo "3. Record demo video (see DEMO_VIDEO_STRATEGY.md)"
echo ""
echo "4. Update README.md with live demo URL:"
echo -e "   ${BLUE}Live Demo: $CLOUD_RUN_URL${NC}"
echo ""
echo "5. Submit to competition before March 17, 2026"
echo ""
echo "=========================================="
echo "Documentation:"
echo "=========================================="
echo ""
echo "- Deployment details: deployment_outputs.txt"
echo "- Environment config: lib/core/config/environment.dart"
echo "- Terraform state: infrastructure/terraform/terraform.tfstate"
echo ""
echo "=========================================="
echo "Support:"
echo "=========================================="
echo ""
echo "- View logs: gcloud run services logs read $SERVICE_NAME --region=$REGION"
echo "- Cloud Console: https://console.cloud.google.com/run?project=$PROJECT_ID"
echo "- Deployment Guide: DEPLOYMENT_GUIDE.md"
echo ""
echo "=========================================="
echo "Good luck with the competition! 🚀"
echo "=========================================="
