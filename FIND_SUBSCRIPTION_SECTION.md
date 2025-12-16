# Where to Find "In-App Purchases and Subscriptions" Section

## Why You Can't See It Yet

The "In-App Purchases and Subscriptions" section only appears **AFTER** you:
1. ✅ Create an app version (e.g., 1.0.3)
2. ✅ Upload a binary/build to that version

## Step-by-Step: How to Make It Appear

### Step 1: Create/Go to App Version

1. Open **App Store Connect**
2. Go to **My Apps** → Select **Hero - Deutsch B2 Beruf**
3. Click on **App Store** tab (left sidebar)
4. Under **iOS App**, you'll see versions
5. If version 1.0.3 doesn't exist:
   - Click **"+"** next to iOS App
   - Or click on an existing version to edit it

### Step 2: Upload Your Binary (Important!)

The subscription section only appears AFTER you upload a build:

1. In Xcode:
   - Product → Archive
   - Wait for archive to complete
   - Click **"Distribute App"**
   - Choose **"App Store Connect"**
   - Follow the wizard to upload

2. OR use Transporter app:
   - Export your .ipa file
   - Upload via Transporter

3. In App Store Connect:
   - Go to **TestFlight** tab
   - Wait for processing (10-30 minutes)
   - Go back to **App Store** tab → Your version
   - The build should appear under **"Build"** section

### Step 3: Now You Can See It!

After the build is uploaded and processed:

1. Go to **App Store** tab
2. Click on your version (1.0.3)
3. Scroll down past:
   - Version Information
   - Screenshots
   - Description
   - Keywords
   - Support URL
   - Marketing URL
   - **Then you'll see: "In-App Purchases and Subscriptions"** ✅

## Alternative: If You Want to Set Up Subscription First

You can set up the subscription BEFORE uploading the build:

### Option A: Set Up Subscription Independently

1. Go to **Features** tab (left sidebar)
2. Click **In-App Purchases**
3. Click **"+"** → **"Subscriptions"**
4. Create your subscription group and product
5. Later, when you create the app version with uploaded build, you can link it

### Option B: Set Up Subscription from App Version Page

Even if the section isn't visible yet, you can:

1. Go to **App Store** tab → Your app version
2. Complete other required fields first:
   - Version number
   - Release notes
   - Screenshots
3. Upload your binary/build
4. After build processes, the section will appear
5. Then link your subscription

## Current Status Check

**Where are you now?**

- [ ] Have you created version 1.0.3 in App Store Connect?
- [ ] Have you uploaded a binary/build for version 1.0.3?
- [ ] Has the build finished processing (shows in TestFlight)?
- [ ] Are you on the App Store tab → Version 1.0.3 page?

## Visual Guide: Where It Should Be

```
App Store Connect
  └── My Apps
      └── Hero - Deutsch B2 Beruf
          └── App Store (tab)
              └── iOS App
                  └── Version 1.0.3
                      ├── Version Information
                      ├── Screenshots
                      ├── Description
                      ├── Keywords
                      ├── Support URL
                      ├── Marketing URL
                      └── ⬇️ AFTER BUILD UPLOAD ⬇️
                          └── In-App Purchases and Subscriptions ← HERE!
```

## What to Do Right Now

1. **If you haven't uploaded a build yet:**
   - Upload your build first (via Xcode Archive or Transporter)
   - Wait for processing
   - Then look for the section

2. **If you want to set up subscription now:**
   - Go to **Features** → **In-App Purchases**
   - Create your subscription there
   - Link it to app version later (after build upload)

3. **If build is uploaded:**
   - Make sure you're on the correct version page (1.0.3)
   - Scroll all the way down
   - Look for "In-App Purchases and Subscriptions"

---

**Quick Test:** 
- Can you see the "Build" section on your version page?
- If NO → You need to upload a build first
- If YES → Scroll down, the subscription section should be below it





