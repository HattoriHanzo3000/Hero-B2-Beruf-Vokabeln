# Test Store Setup Guide

## ✅ Yes, You Need to Set Up the Same Products!

When you have separate API keys (Test Store vs Production), you need to configure **the same products** in both environments.

---

## Your Products

You have **3 products** that need to be set up in both Test Store and Production:

1. `hero.premium.monthly`
2. `hero.premium.yearly`
3. `hero.premium.lifetime`

---

## Step-by-Step: Test Store Setup

### 1. Switch to Test Store Key

1. Go to: https://app.revenuecat.com
2. Your Project → **Project Settings** → **API Keys**
3. Find your **Test Store** key: `test_awDtpFpEwzXmwXUfynkCRiBrIuD`
4. **Note:** RevenueCat may automatically switch contexts, or you might need to select the Test Store environment

### 2. Create Entitlement (Same as Production)

1. Go to: **Entitlements**
2. Create or verify entitlement: `premium`
   - If it doesn't exist, create it
   - Description: "Premium subscription access"
   - **Same identifier as production:** `premium`

### 3. Add Products (Same 3 Products)

1. Go to: **Products**
2. Add the same 3 products:
   - `hero.premium.monthly`
   - `hero.premium.yearly`
   - `hero.premium.lifetime`
3. Link each product to the `premium` entitlement
4. **Important:** Use the **exact same product IDs** as production

### 4. Configure Offerings (Same Structure)

1. Go to: **Offerings**
2. Create or update default offering
3. Add packages for each product:
   - **Monthly Package** → `hero.premium.monthly`
   - **Yearly Package** → `hero.premium.yearly`
   - **Lifetime Package** → `hero.premium.lifetime`
4. Set default package (usually monthly or yearly)

---

## Why Same Products?

### ✅ Product IDs Must Match
- Your app code uses: `hero.premium.monthly`, `hero.premium.yearly`, `hero.premium.lifetime`
- These IDs come from **App Store Connect** (they're the same everywhere)
- RevenueCat just needs to know about them in both environments

### ✅ Different Environments, Same Products
- **Test Store:** Uses sandbox/test purchases (free testing)
- **Production:** Uses real purchases (real money)
- **Same product IDs** in both environments

---

## Quick Checklist

For **Test Store** key (`test_awDtpFpEwzXmwXUfynkCRiBrIuD`):

- [ ] Entitlement `premium` created
- [ ] Product `hero.premium.monthly` added and linked to `premium`
- [ ] Product `hero.premium.yearly` added and linked to `premium`
- [ ] Product `hero.premium.lifetime` added and linked to `premium`
- [ ] Offering created with all 3 packages
- [ ] Default package set

For **Production** key (`appl_rcEmwNiUYUgSBkoXePHgjfKFjcI`):

- [ ] Entitlement `premium` created
- [ ] Product `hero.premium.monthly` added and linked to `premium`
- [ ] Product `hero.premium.yearly` added and linked to `premium`
- [ ] Product `hero.premium.lifetime` added and linked to `premium`
- [ ] Offering created with all 3 packages
- [ ] Default package set

---

## Important Notes

### ✅ What's the Same
- Product IDs (must match exactly)
- Entitlement ID (`premium`)
- Offering structure

### ⚠️ What's Different
- **Test Store:** Sandbox purchases (free, for testing)
- **Production:** Real purchases (real money)
- **API Keys:** Different keys for each environment

---

## Testing After Setup

Once both environments are set up:

1. **Test with Test Store Key** (DEBUG builds):
   - Run app in simulator or TestFlight
   - Make test purchases (free, sandbox)
   - Verify products load correctly
   - Verify purchases work

2. **Test with Production Key** (RELEASE builds):
   - Test with real sandbox account
   - Verify products load correctly
   - Verify purchases work

---

## Common Questions

### Q: Do I need to create products twice?
**A:** Yes, but RevenueCat might auto-sync them. Check both environments to be sure.

### Q: Can I use different product IDs for test?
**A:** No! Product IDs must match App Store Connect exactly. Same IDs everywhere.

### Q: What if products don't show up in Test Store?
**A:** Make sure you're viewing the Test Store environment, and manually add them if needed.

### Q: Do I need separate entitlements?
**A:** No, same entitlement ID (`premium`) in both environments.

---

## Summary

✅ **Yes, set up the same 3 products in Test Store**  
✅ **Use the same product IDs**  
✅ **Use the same entitlement ID**  
✅ **Same offering structure**

The only difference is the API key and the purchase environment (sandbox vs production).

---

*After setup, test purchases will work with the Test Store key, and real purchases will work with the Production key!*
