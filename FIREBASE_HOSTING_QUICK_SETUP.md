# Quick Firebase Hosting Setup for app-ads.txt

Since Google Sites cannot host app-ads.txt files, use Firebase Hosting (free and easy).

## Prerequisites

- Google account (same one you use for AdMob)
- Terminal/Command Line access

## Quick Setup (5-10 minutes)

### 1. Install Firebase CLI

**On macOS (using Homebrew):**
```bash
brew install firebase-tools
```

**Or using npm (if you have Node.js):**
```bash
npm install -g firebase-tools
```

**Verify:**
```bash
firebase --version
```

### 2. Login to Firebase

```bash
firebase login
```

This opens your browser to authenticate with your Google account.

### 3. Create Project Directory

```bash
# Navigate to your project directory
cd "/Users/ildarelchaninov/iOS Apps/B2 Berufssprachkurs"

# Create Firebase hosting directory
mkdir firebase-hosting
cd firebase-hosting
```

### 4. Initialize Firebase Hosting

```bash
firebase init hosting
```

**Answer the prompts:**
- **Select a Firebase project:** 
  - Choose "Create a new project" or select existing
  - Project name: `gizatech-app-ads` (or any name)
- **What do you want to use as your public directory?** 
  - Type: `public` and press Enter
- **Configure as a single-page app?** 
  - Type: `N` and press Enter
- **Set up automatic builds and deploys with GitHub?** 
  - Type: `N` and press Enter

### 5. Add app-ads.txt File

```bash
# Create public directory (if it doesn't exist)
mkdir -p public

# Copy the app-ads.txt file
cp ../app-ads.txt public/
```

**Or manually create the file:**
```bash
cat > public/app-ads.txt << 'EOF'
google.com, pub-1380989901130305, DIRECT, f08c47fec0942fa0
EOF
```

### 6. Deploy

```bash
firebase deploy --only hosting
```

**You'll see output like:**
```
✔ Deploy complete!

Hosting URL: https://your-project-name.web.app
```

### 7. Verify

Open your browser and visit:
```
https://your-project-name.web.app/app-ads.txt
```

You should see:
```
google.com, pub-1380989901130305, DIRECT, f08c47fec0942fa0
```

### 8. Update App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Hero - Deutsch B2 Beruf** → **App Information**
3. Set **Marketing URL** to: `https://your-project-name.web.app`
4. Save

### 9. Wait for Verification

- Wait 24-48 hours
- Check AdMob dashboard for verification status

## Optional: Connect Custom Domain

If you want to use `gizatech.de` instead of the Firebase URL:

1. In [Firebase Console](https://console.firebase.google.com/)
2. Go to **Hosting** → **Add custom domain**
3. Enter: `gizatech.de`
4. Follow DNS configuration instructions
5. Wait 24-48 hours for DNS propagation
6. Update App Store Connect Marketing URL to `https://gizatech.de`

## Troubleshooting

### Firebase CLI not found
- Make sure you installed it: `brew install firebase-tools`
- Or use: `npm install -g firebase-tools`

### Login fails
- Make sure you're using the same Google account as AdMob
- Try: `firebase logout` then `firebase login` again

### File not accessible after deploy
- Check the file is in the `public` directory
- Verify the filename is exactly `app-ads.txt` (lowercase)
- Try: `firebase deploy --only hosting` again

## File Structure

After setup, your directory should look like:
```
firebase-hosting/
├── .firebaserc
├── firebase.json
└── public/
    └── app-ads.txt
```

## Next Steps

1. ✅ File deployed to Firebase
2. ✅ Marketing URL updated in App Store Connect
3. ⏳ Wait 24-48 hours
4. ✅ Check AdMob verification status

---

**That's it!** Your app-ads.txt file is now hosted and AdMob will be able to verify it.

