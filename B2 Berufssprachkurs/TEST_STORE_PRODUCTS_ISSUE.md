# Test Store Products Issue - Can Only See "Full Premium Access"

## The Problem

When trying to add products to Test Store, you only see "Full Premium Access" and no other options.

---

## Why This Happens

RevenueCat shows products that are:
1. **Created in App Store Connect** (must exist first)
2. **Synced to RevenueCat** (automatic or manual)
3. **Available in the current environment** (Test Store vs Production)

If you only see "Full Premium Access", it means:
- ✅ RevenueCat is connected to App Store Connect
- ❌ But your 3 products (`hero.premium.monthly`, `hero.premium.yearly`, `hero.premium.lifetime`) might not exist in App Store Connect yet

---

## Solution: Check App Store Connect First

### Step 1: Verify Products in App Store Connect

1. Go to: https://appstoreconnect.apple.com
2. **My Apps** → Select your app: **Hero - Deutsch B2 Beruf**
3. Go to: **Features** → **In-App Purchases**
4. Check if these products exist:
   - `hero.premium.monthly`
   - `hero.premium.yearly`
   - `hero.premium.lifetime`

### Step 2: If Products Don't Exist in App Store Connect

**You need to create them first:**

1. In App Store Connect → **In-App Purchases**
2. Click **+** (Create)
3. Select **Auto-Renewable Subscription**
4. Create each product:
   - **Product ID:** `hero.premium.monthly`
   - **Product ID:** `hero.premium.yearly`
   - **Product ID:** `hero.premium.lifetime`
5. Fill in pricing, descriptions, etc.
6. **Submit for review** (or save as draft)

### Step 3: Wait for Sync (or Force Sync)

After creating products in App Store Connect:

1. **Wait 5-10 minutes** for automatic sync
2. Or **force sync** in RevenueCat:
   - Go to RevenueCat Dashboard
   - **Products** → Look for sync button
   - Or go to **Project Settings** → **Integrations** → **App Store Connect**
   - Check connection status

---

## Alternative: Create Products Directly in RevenueCat

If you can't create products in App Store Connect right now, you can create them in RevenueCat:

### Method 1: Add Product Manually

1. In RevenueCat Dashboard → **Products**
2. Click **+ Add Product** or **Create Product**
3. Enter Product ID: `hero.premium.monthly`
4. Select type: **Subscription** (Auto-Renewable)
5. Repeat for all 3 products

**Note:** These will need to match App Store Connect eventually, but this lets you test now.

### Method 2: Use "Full Premium Access" for Testing

If you can't create products right now:

1. Use "Full Premium Access" for testing
2. Link it to your `premium` entitlement
3. Test the purchase flow
4. Later, when products are in App Store Connect, switch to the real products

---

## What "Full Premium Access" Might Be

"Full Premium Access" could be:
- A default/example product RevenueCat created
- A product that already exists in App Store Connect
- A placeholder product

**Check:**
1. Click on "Full Premium Access" to see its Product ID
2. If it matches one of your products, you can use it
3. If not, you'll need to create the products first

---

## Quick Fix: Use Existing Product for Testing

If you just need to test the integration:

1. **Use "Full Premium Access"** for now
2. Link it to your `premium` entitlement
3. Create an offering with this product
4. Test the purchase flow
5. **Later:** Replace with your 3 products when they're in App Store Connect

---

## Step-by-Step: Create Products in App Store Connect

### 1. Create Subscription Group (if needed)

1. App Store Connect → **In-App Purchases**
2. Create **Subscription Group** (e.g., "Premium Subscriptions")
3. Add your 3 products to this group

### 2. Create Each Product

For each product (`hero.premium.monthly`, `hero.premium.yearly`, `hero.premium.lifetime`):

1. Click **+** → **Auto-Renewable Subscription**
2. **Product ID:** Enter exact ID (e.g., `hero.premium.monthly`)
3. **Reference Name:** "Monthly Premium" (for your reference)
4. **Subscription Duration:** 
   - Monthly: 1 month
   - Yearly: 1 year
   - Lifetime: (this might be a non-consumable, not subscription)
5. **Pricing:** Set your prices
6. **Localization:** Add descriptions
7. **Save** (or Submit for Review)

### 3. Wait for RevenueCat Sync

- Usually syncs within 5-10 minutes
- Check RevenueCat Dashboard → **Products**
- Products should appear automatically

---

## For Test Store Specifically

### Option 1: Use Same Products (Recommended)

- Products in App Store Connect work for both Test Store and Production
- Test Store uses **sandbox purchases** (free testing)
- Production uses **real purchases**
- **Same product IDs** in both environments

### Option 2: Create Test-Only Products (Not Recommended)

- You could create test products, but it's unnecessary
- Same products work for both environments
- Just use different API keys

---

## Troubleshooting

### Products Still Not Showing?

1. **Check App Store Connect:**
   - Are products created?
   - Are they in "Ready to Submit" or "Approved" status?
   - Draft products might not sync

2. **Check RevenueCat Connection:**
   - Go to **Project Settings** → **Integrations** → **App Store Connect**
   - Verify connection is active
   - Check sync status

3. **Manual Sync:**
   - Some RevenueCat dashboards have a "Sync" or "Refresh" button
   - Try manually syncing products

4. **Check Environment:**
   - Make sure you're in the right environment (Test Store vs Production)
   - Products should appear in both

---

## Quick Solution for Now

**If you need to test immediately:**

1. ✅ Use "Full Premium Access" for now
2. ✅ Link it to `premium` entitlement
3. ✅ Create offering with this product
4. ✅ Test purchase flow
5. ✅ Later: Replace with your 3 products when ready

**Then later:**
1. Create products in App Store Connect
2. Wait for sync to RevenueCat
3. Update offerings to use real products

---

## Summary

**The issue:** Products don't exist in App Store Connect yet, so RevenueCat can't show them.

**The solution:**
1. Create products in App Store Connect first
2. Wait for RevenueCat to sync
3. Then they'll appear in both Test Store and Production

**Quick fix:** Use "Full Premium Access" for testing now, switch to real products later.

---

*Need help creating products in App Store Connect? Let me know!*
