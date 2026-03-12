# Quick Start - GCP Deployment

**Time Required:** 30-45 minutes  
**Prerequisites:** Mac with Homebrew installed

---

## Step 1: Install Required Tools (5 minutes)

Run the installation script:

```bash
./setup_gcp_tools.sh
```

This will install:
- Google Cloud SDK (gcloud)
- Terraform
- Docker Desktop (if needed)

After installation, **restart your terminal** or run:

```bash
source ~/.zshrc  # or ~/.bash_profile
```

---

## Step 2: Verify Installation

Check that everything is installed:

```bash
gcloud --version
terraform --version
docker --version
```

You should see version numbers for all three tools.

---

## Step 3: Deploy to Google Cloud (20-30 minutes)

Run the automated deployment script:

```bash
./deploy_to_gcp.sh
```

The script will guide you through:

1. **Login to Google Cloud** - Opens browser for authentication
2. **Create/Select Project** - Creates `ghost-accountant-prod` project
3. **Enable Billing** - You'll need to enable billing in the console
4. **Enable APIs** - Automatically enables required Google Cloud APIs
5. **Configure Gemini API** - Enter your API key or use Vertex AI
6. **Deploy Infrastructure** - Uses Terraform to create all resources
7. **Test Deployment** - Verifies the service is running

---

## Step 4: Get Your Gemini API Key (if needed)

If you don't have a Gemini API key yet:

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Click "Create API Key"
3. Copy the key
4. Paste it when the deployment script asks

**Alternative:** Use Vertex AI (no separate key needed) - just press 'n' when asked about API key.

---

## Step 5: Enable Billing

When the script prompts you, go to:

```
https://console.cloud.google.com/billing/linkedaccount?project=ghost-accountant-prod
```

1. Click "Link a billing account"
2. Select your billing account (or create one)
3. Click "Set account"
4. Return to terminal and press Enter

**Note:** Google Cloud offers $300 free credit for new accounts!

---

## What Gets Deployed

The deployment script creates:

- ✅ **Cloud Run Service** - Serverless AI orchestrator
- ✅ **Vertex AI** - Gemini 3 Flash/Pro integration
- ✅ **Cloud Storage** - Receipt storage bucket
- ✅ **Firestore** - Real-time database
- ✅ **IAM Roles** - Service account with proper permissions
- ✅ **Auto-scaling** - 0-100 instances based on traffic

---

## After Deployment

You'll receive:

1. **Cloud Run URL** - Your live API endpoint
2. **Deployment Details** - Saved to `deployment_outputs.txt`
3. **Environment Config** - Auto-generated `lib/core/config/environment.dart`

Example output:
```
Cloud Run URL:       https://ghost-accountant-ai-xxxxx-uc.a.run.app
Receipts Bucket:     ghost-accountant-prod-receipts
Service Account:     ghost-ai-orchestrator@ghost-accountant-prod.iam.gserviceaccount.com
```

---

## Testing Your Deployment

Test the health endpoint:

```bash
curl https://ghost-accountant-ai-xxxxx-uc.a.run.app/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "ghost-accountant-ai-orchestrator",
  "version": "5.0.0",
  "gemini_api": "connected",
  "vertex_ai": "connected"
}
```

---

## Running the Flutter App

After deployment, run the app:

```bash
# Get dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Or run on your device
flutter run
```

The app will automatically use the deployed Cloud Run service!

---

## Troubleshooting

### Issue: "gcloud: command not found"

**Solution:** Restart your terminal or run:
```bash
source ~/.zshrc
```

### Issue: "Billing not enabled"

**Solution:** 
1. Go to https://console.cloud.google.com/billing
2. Link a billing account to your project
3. Wait 2-3 minutes for it to propagate

### Issue: "Permission denied"

**Solution:** Make scripts executable:
```bash
chmod +x setup_gcp_tools.sh deploy_to_gcp.sh
```

### Issue: "Docker not running"

**Solution:** 
1. Open Docker Desktop from Applications
2. Wait for it to start (green icon in menu bar)
3. Run the deployment script again

### Issue: "Terraform state locked"

**Solution:**
```bash
cd infrastructure/terraform
terraform force-unlock <LOCK_ID>
```

---

## Viewing Logs

View Cloud Run logs:

```bash
gcloud run services logs read ghost-accountant-ai-orchestrator \
  --region=us-central1 \
  --limit=50
```

Or view in Cloud Console:
```
https://console.cloud.google.com/run?project=ghost-accountant-prod
```

---

## Cost Estimate

**Monthly cost for 100 users:**
- Cloud Run: $0.00 (within free tier)
- Gemini API: ~$78.00 (100 receipts/user)
- Cloud Storage: ~$2.00 (100GB receipts)
- Firestore: $0.00 (within free tier)

**Total: ~$80/month = $0.80 per user**

**Free Tier Benefits:**
- Cloud Run: 2M requests/month free
- Cloud Storage: 5GB free
- Firestore: 50K reads, 20K writes free
- $300 credit for new Google Cloud accounts

---

## Next Steps

After successful deployment:

1. ✅ Update README.md with your Cloud Run URL
2. ✅ Record demo video (see DEMO_VIDEO_STRATEGY.md)
3. ✅ Write Medium article (see MEDIUM_ARTICLE_STRATEGY.md)
4. ✅ Submit to competition before March 17, 2026

---

## Support

- **Deployment Guide:** DEPLOYMENT_GUIDE.md
- **Competition Status:** COMPETITION_STATUS.md
- **Google Cloud Console:** https://console.cloud.google.com
- **Cloud Run Docs:** https://cloud.google.com/run/docs

---

## Summary

```bash
# 1. Install tools
./setup_gcp_tools.sh

# 2. Restart terminal
source ~/.zshrc

# 3. Deploy to GCP
./deploy_to_gcp.sh

# 4. Test deployment
curl <YOUR_CLOUD_RUN_URL>/health

# 5. Run Flutter app
flutter run
```

**That's it! You're ready for the competition! 🚀**
