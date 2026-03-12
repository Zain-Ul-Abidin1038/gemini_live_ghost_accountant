# ⚠️ Enable Billing Required

Your Google Cloud project `ghost-accountant-prod` has been created successfully!

However, **billing must be enabled** before we can deploy the infrastructure.

---

## 🔗 Enable Billing Now

**Click this link to enable billing:**

https://console.cloud.google.com/billing/linkedaccount?project=ghost-accountant-prod

---

## 📋 Steps to Enable Billing

1. Click the link above (it will open in your browser)
2. Click **"Link a billing account"**
3. Select your billing account (or create a new one)
4. Click **"Set account"**

---

## 💰 New Account Benefits

If this is a new Google Cloud account, you get:

- ✅ **$300 free credit**
- ✅ Valid for 90 days
- ✅ No charges until you upgrade
- ✅ More than enough for this project

---

## 📊 Expected Monthly Cost

After free credit expires:

- **Cloud Run:** $0.00 (free tier)
- **Gemini API:** ~$0.78 per user
- **Cloud Storage:** ~$0.02 per user
- **Firestore:** $0.00 (free tier)

**Total:** ~$0.80 per user per month

---

## ✅ After Enabling Billing

Once billing is enabled, run:

```bash
./auto_deploy_gcp.sh
```

The script will automatically:
1. ✅ Enable required APIs
2. ✅ Deploy infrastructure with Terraform
3. ✅ Create Cloud Run service
4. ✅ Set up Vertex AI
5. ✅ Configure Cloud Storage
6. ✅ Test the deployment

---

## 🆘 Troubleshooting

### "I don't have a billing account"

1. Go to: https://console.cloud.google.com/billing
2. Click **"Create account"**
3. Enter your payment information
4. You won't be charged (free $300 credit)

### "Billing is already enabled"

If you already enabled billing, just run:

```bash
./auto_deploy_gcp.sh
```

---

## 📞 Need Help?

- **Google Cloud Billing Docs:** https://cloud.google.com/billing/docs
- **Free Tier Details:** https://cloud.google.com/free
- **Support:** https://cloud.google.com/support

---

**Enable billing now, then run the deployment script!** 🚀
