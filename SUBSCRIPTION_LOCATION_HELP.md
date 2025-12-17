# Finding Subscription Section in App Store Connect

## Current Situation

You're seeing these fields:
- ✅ What's New in This Version
- ✅ Keywords
- ✅ Support URL
- ✅ Marketing URL
- ✅ Version
- ✅ Copyright
- ❌ No "In-App Purchases and Subscriptions" section visible

## Why You Don't See It

The "In-App Purchases and Subscriptions" section appears **AFTER** you:
1. Upload a binary/build
2. Build finishes processing

OR it might be in a different location in the interface.

## Solution: Two Ways to Add Subscription

### Method 1: Add Subscription from Features Tab (Easier!)

1. **Go to left sidebar** → Click **"Features"** tab
2. Click **"In-App Purchases"**
3. Click **"+"** button (top right)
4. Select **"Subscriptions"**
5. Create your subscription here
6. After creating, it will be available to link to app versions

### Method 2: Check if Build is Uploaded

The subscription section might appear after you upload a build:

1. Scroll ALL the way down on the version page
2. Look for **"Build"** section - do you see it?
   - If YES → Scroll below it, subscription section should be there
   - If NO → You need to upload a build first

## Step-by-Step: Create Subscription from Features Tab

### Step 1: Navigate to Features
```
App Store Connect
  └── My Apps
      └── Hero - Deutsch B2 Beruf
          └── Features (left sidebar) ← CLICK HERE
              └── In-App Purchases
```

### Step 2: Create Subscription Group
1. Click **"+"** (top right)
2. Select **"Subscriptions"**
3. Click **"Create Subscription Group"**
4. Name: `Premium Subscription`
5. Click **"Create"**

### Step 3: Create Subscription Product
1. Inside the subscription group, click **"+"**
2. Fill in details:
   - **Reference Name**: `Pro Access | Monthly`
   - **Product ID**: `monthly_1.99_3d_trial` ⚠️ Must match your code!
   - **Subscription Duration**: `1 Month`
   - **Price**: `$1.99` (or your currency)
   - **Free Trial**: `3 Days`

3. Add localization:
   - **English**: 
     - Display Name: `Premium Monthly`
     - Description: `Unlock the full Hero experience`
   - **German**:
     - Display Name: `Premium Monatlich`
     - Description: `Schalte die vollständige Hero-Erfahrung frei`

4. Click **"Save"**

### Step 4: Link to App Version (After Build Upload)

Once you upload a build:
1. Go back to **App Store** tab → Version 1.0.3
2. Scroll down
3. You should now see "In-App Purchases and Subscriptions"
4. Click **"+"** or **"Manage"**
5. Select your subscription: `monthly_1.99_3d_trial`
6. Click **"Done"**

## Alternative: Check Current Interface

The App Store Connect interface sometimes changes. Try:

1. **Scroll to very bottom** of the version page
2. Look for any section related to:
   - "In-App Purchases"
   - "Subscriptions"
   - "Auto-Renewable Subscriptions"
   - "IAPs"

3. Or check if there's a **"+"** button anywhere that says "Add" or "Manage"

## Quick Check List

Before you can link subscription to version:
- [ ] Have you uploaded a build/binary for version 1.0.3?
- [ ] Is the build showing under "Build" section on version page?
- [ ] Have you created the subscription in Features tab?

## What You Can Do Right Now

Even without the section visible, you CAN:

✅ **Create the subscription** (Features → In-App Purchases)
✅ **Complete other version info** (keywords, URLs, etc.)
✅ **Upload your build** (this makes the section appear)

## After Uploading Build

Once your build is processed:
1. Refresh the version page
2. Scroll to bottom
3. You should see:
   ```
   ...
   Version
   Copyright
   Routing App Coverage File
   
   ⬇️ BUILD SECTION (after upload) ⬇️
   Build
   [Select a build]
   
   ⬇️ SUBSCRIPTION SECTION (appears here) ⬇️
   In-App Purchases and Subscriptions
   [Link your subscription here]
   ```

## Need Help?

Tell me:
1. Have you uploaded a build? (YES/NO)
2. Do you see a "Build" section? (YES/NO)
3. Can you access "Features" → "In-App Purchases"? (YES/NO)

Based on your answers, I'll give you exact next steps!






