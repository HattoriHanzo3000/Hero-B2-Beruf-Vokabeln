# How to Submit Your Subscription with App Version 1.0.3

## Understanding the Process

**Important Rule:** Your FIRST subscription must be submitted together with a new app version. You cannot submit subscriptions separately on their first submission.

## Step-by-Step Instructions

### Step 1: Create Subscription Group (If Not Already Done)

1. Go to **App Store Connect** → Your App → **Features** → **In-App Purchases**
2. Click **"+"** → Select **"Subscriptions"**
3. Click **"Create Subscription Group"**
4. Name it: **"Premium Subscription"** (or similar)
5. Click **"Create"**

### Step 2: Create Your Subscription Product

1. Inside your Subscription Group, click **"+"** to add a subscription
2. Fill in the details:

   **Subscription Information:**
   - **Reference Name**: `Pro Access | Monthly`
   - **Product ID**: `monthly_1.99_3d_trial` (must match your code!)
   - **Subscription Duration**: `1 Month`
   - **Price**: Select `$1.99` (or your local currency equivalent)

   **Subscription Display Name:**
   - English: `Premium Monthly`
   - German: `Premium Monatlich`

   **Description:**
   - English: `Unlock the full Hero experience with unlimited access to all features, ad-free experience, and priority support.`
   - German: `Schalte die vollständige Hero-Erfahrung mit unbegrenztem Zugriff auf alle Funktionen, werbefreier Nutzung und Prioritäts-Support frei.`

3. **Free Trial:**
   - Enable: **Yes**
   - Duration: **3 Days**

4. **Review Information:**
   - Add a screenshot if needed
   - Fill in review notes if required

5. Click **"Save"**

### Step 3: Link Subscription to App Version

1. Go to your app's **App Store** tab
2. Find version **1.0.3** (or create it if not exists)
3. Scroll down to **"In-App Purchases and Subscriptions"** section
4. Click **"+"** or **"Manage"**
5. Select your subscription: **`monthly_1.99_3d_trial`**
6. Click **"Done"** or **"Add"**

### Step 4: Complete App Version Information

Make sure your app version has:
- ✅ Version number: 1.0.3
- ✅ Build number: 4
- ✅ What's New (Release Notes) - English and German
- ✅ Screenshots (if needed)
- ✅ **Subscription linked** (from Step 3)

### Step 5: Submit for Review

1. Scroll to the bottom of your app version page
2. Click **"Submit for Review"**
3. Confirm that:
   - ✅ Subscription is included
   - ✅ All information is complete
   - ✅ Version matches your uploaded binary

4. Click **"Submit"**

---

## Important Notes

### ✅ Do This:
- ✅ Create subscription FIRST (before linking to app version)
- ✅ Link subscription to app version BEFORE submitting
- ✅ Submit app version and subscription TOGETHER the first time
- ✅ Make sure Product ID matches exactly: `monthly_1.99_3d_trial`

### ❌ Don't Do This:
- ❌ Don't submit the app version without linking the subscription first
- ❌ Don't try to submit subscription separately (first time)
- ❌ Don't change Product ID after linking (will break the connection)

---

## What Happens Next?

1. **Initial Review**: App Store reviews both your app AND subscription together
2. **Approval**: If approved, both app and subscription go live
3. **Future Subscriptions**: After first submission, you can add more subscriptions independently

---

## Troubleshooting

### "Subscription not found in App Store Connect"
- Make sure you created the subscription with Product ID: `monthly_1.99_3d_trial`
- Check that it's in an active subscription group
- Verify it's not in "Removed from Sale" status

### "Cannot find subscription in app version"
- Go back to Step 3 and make sure you clicked "Add" or "Done"
- The subscription should appear in the "In-App Purchases and Subscriptions" section
- If it doesn't appear, refresh the page

### "Subscription pricing error"
- Make sure you've set the price for at least one territory
- Price must match your app's pricing tier
- Check that free trial (3 days) is properly configured

---

## Quick Checklist Before Submission

- [ ] Subscription group created
- [ ] Subscription product created with Product ID: `monthly_1.99_3d_trial`
- [ ] Subscription pricing set ($1.99/month)
- [ ] Free trial set to 3 days
- [ ] Localization added (English & German)
- [ ] Subscription linked to app version 1.0.3
- [ ] App version information complete
- [ ] Binary uploaded
- [ ] Ready to submit for review

---

## Your Current Subscription Details

Based on your code:
- **Product ID**: `monthly_1.99_3d_trial`
- **Price**: $1.99/month
- **Free Trial**: 3 days
- **Reference Name**: Pro Access | Monthly

Make sure these match exactly in App Store Connect!

---

**Need Help?** If you're stuck at any step, let me know which step and what error message you're seeing.





