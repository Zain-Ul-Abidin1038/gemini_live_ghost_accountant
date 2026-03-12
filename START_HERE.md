# 🚀 START HERE - Deploy Ghost Accountant to GCP

**You're 3 commands away from deploying to Google Cloud!**

---

## ⚡ Quick Deploy (30 minutes)

### Step 1: Install Tools

```bash
./setup_gcp_tools.sh
```

Then restart your terminal:
```bash
source ~/.zshrc
```

### Step 2: Deploy to Google Cloud

```bash
./deploy_to_gcp.sh
```

The script will:
- ✅ Login to Google Cloud
- ✅ Create project
- ✅ Enable APIs
- ✅ Deploy infrastructure
- ✅ Test deployment

### Step 3: Run the App

```bash
flutter run
```

---

## 📋 What You Need

1. **Google Account** - For Google Cloud Platform
2. **Billing Enabled** - $300 free credit for new accounts
3. **Gemini API Key** - Get from https://aistudio.google.com/app/apikey
   - Or use Vertex AI (no separate key needed)

---

## 💰 Cost

**Monthly cost:** ~$0.80 per user

- Cloud Run: FREE (within free tier)
- Gemini API: ~$0.78/user
- Storage: ~$0.02/user

**New accounts get $300 free credit!**

---

## 📚 Detailed Guides

- **Quick Start:** QUICK_START_GCP.md
- **Full Guide:** DEPLOYMENT_GUIDE.md
- **Competition Info:** COMPETITION_STATUS.md

---

## 🆘 Need Help?

### Common Issues

**"gcloud: command not found"**
```bash
source ~/.zshrc
```

**"Billing not enabled"**
- Go to: https://console.cloud.google.com/billing
- Link a billing account

**"Permission denied"**
```bash
chmod +x setup_gcp_tools.sh deploy_to_gcp.sh
```

---

## ✅ After Deployment

You'll get:
- 🌐 Live Cloud Run URL
- 📊 Deployment details in `deployment_outputs.txt`
- ⚙️ Auto-configured Flutter app

Then:
1. Record demo video (DEMO_VIDEO_STRATEGY.md)
2. Submit to competition (deadline: March 17, 2026)
3. Win $25,000! 🏆

---

## 🎯 Competition Checklist

- [ ] Deploy to GCP (this guide)
- [ ] Test deployment
- [ ] Record demo video
- [ ] Write Medium article (optional)
- [ ] Submit to Devpost

**5 days remaining!**

---

**Let's go! Run the first command now! 🚀**

```bash
./setup_gcp_tools.sh
```
