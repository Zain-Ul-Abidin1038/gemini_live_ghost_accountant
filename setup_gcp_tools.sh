#!/bin/bash

# Ghost Accountant - GCP Tools Installation Script
# This script installs Google Cloud SDK and Terraform on macOS

set -e  # Exit on error

echo "=========================================="
echo "Ghost Accountant - GCP Tools Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${GREEN}✓ Homebrew is already installed${NC}"
fi

echo ""
echo "=========================================="
echo "Step 1: Installing Google Cloud SDK"
echo "=========================================="
echo ""

# Install Google Cloud SDK
if ! command -v gcloud &> /dev/null; then
    echo -e "${BLUE}Installing Google Cloud SDK via Homebrew...${NC}"
    brew install --cask google-cloud-sdk
    
    # Add gcloud to PATH
    echo ""
    echo -e "${YELLOW}Adding gcloud to your PATH...${NC}"
    
    # Detect shell
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bash_profile"
    fi
    
    # Add gcloud path if not already present
    if ! grep -q "google-cloud-sdk" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Google Cloud SDK" >> "$SHELL_RC"
        echo 'source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"' >> "$SHELL_RC"
        echo 'source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"' >> "$SHELL_RC"
        echo -e "${GREEN}✓ Added gcloud to $SHELL_RC${NC}"
    fi
    
    # Source the file to make gcloud available immediately
    source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc" 2>/dev/null || true
    
    echo -e "${GREEN}✓ Google Cloud SDK installed successfully${NC}"
else
    echo -e "${GREEN}✓ Google Cloud SDK is already installed${NC}"
    gcloud version
fi

echo ""
echo "=========================================="
echo "Step 2: Installing Terraform"
echo "=========================================="
echo ""

# Install Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${BLUE}Installing Terraform via Homebrew...${NC}"
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
    echo -e "${GREEN}✓ Terraform installed successfully${NC}"
else
    echo -e "${GREEN}✓ Terraform is already installed${NC}"
    terraform version
fi

echo ""
echo "=========================================="
echo "Step 3: Installing Docker (if needed)"
echo "=========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker not found. You'll need Docker Desktop for building images.${NC}"
    echo -e "${BLUE}Installing Docker Desktop...${NC}"
    brew install --cask docker
    echo -e "${GREEN}✓ Docker Desktop installed${NC}"
    echo -e "${YELLOW}⚠️  Please start Docker Desktop from Applications before continuing${NC}"
else
    echo -e "${GREEN}✓ Docker is already installed${NC}"
    docker --version
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}✓ Google Cloud SDK installed${NC}"
echo -e "${GREEN}✓ Terraform installed${NC}"
echo -e "${GREEN}✓ Docker installed${NC}"
echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Restart your terminal or run:"
echo -e "   ${BLUE}source ~/.zshrc${NC}  (or ~/.bash_profile)"
echo ""
echo "2. Login to Google Cloud:"
echo -e "   ${BLUE}gcloud auth login${NC}"
echo ""
echo "3. Set your project:"
echo -e "   ${BLUE}gcloud config set project YOUR_PROJECT_ID${NC}"
echo ""
echo "4. Configure Docker for GCR:"
echo -e "   ${BLUE}gcloud auth configure-docker${NC}"
echo ""
echo "5. Run the deployment script:"
echo -e "   ${BLUE}./deploy_to_gcp.sh${NC}"
echo ""
echo "=========================================="
echo "For detailed instructions, see:"
echo "  - DEPLOYMENT_GUIDE.md"
echo "  - COMPETITION_STATUS.md"
echo "=========================================="
