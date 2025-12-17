# Fix: Add Packages to Your Offering

## What You Have

✅ **Entitlement:** `Premium`  
✅ **6 Products:**
- Production: `hero.premium.monthly`, `hero.premium.yearly`, `hero.premium.lifetime`
- Test Store: `monthly`, `yearly`, `lifetime`

❌ **Missing:** Packages in your Offering!

---

## The Problem

Your products exist, but your **Offering doesn't have any packages** configured. That's why you're seeing the error:

```
ERROR: Offering 'default' has no packages configured
```

---

## Quick Fix: Add Packages to Offering

### Step 1: Go to Offerings

1. RevenueCat Dashboard → **Offerings**
2. Click on **"default"** offering (or create new if doesn't exist)

### Step 2: Add Packages

You need to add **3 packages** to your offering:

#### Package 1: Monthly
1. Click **+ Add Package**
2. **Package Identifier:** `monthly` (or `$rc_monthly`)
3. **Product:** Select **"monthly"** (Test Store product)
   - OR select **"Premium Monthly"** (hero.premium.monthly) if you want to use production
4. **Save**

#### Package 2: Yearly
1. Click **+ Add Package**
2. **Package Identifier:** `yearly` (or `$rc_yearly`)
3. **Product:** Select **"yearly"** (Test Store product)
   - OR select **"Premium Yearly"** (hero.premium.yearly) if you want to use production
4. **Save**

#### Package 3: Lifetime
1. Click **+ Add Package**
2. **Package Identifier:** `lifetime` (or `$rc_lifetime`)
3. **Product:** Select **"lifetime"** (Test Store product)
   - OR select **"Premium Lifetime"** (hero.premium.lifetime) if you want to use production
4. **Save**

### Step 3: Set Default Package (Optional)

1. In the offering, mark one package as **"Default"**
2. Usually set Monthly or Yearly as default

### Step 4: Verify

Your offering should now show:
- ✅ Package: Monthly → Product: monthly (or Premium Monthly)
- ✅ Package: Yearly → Product: yearly (or Premium Yearly)
- ✅ Package: Lifetime → Product: lifetime (or Premium Lifetime)

---

## Important: Product ID Mismatch

### The Issue

Your app code is looking for:
- `hero.premium.monthly`
- `hero.premium.yearly`
- `hero.premium.lifetime`

But your Test Store products are:
- `monthly`
- `yearly`
- `lifetime`

### Solution Options

#### Option 1: Use Production Products for Test Store (Recommended)

**For Test Store offering, use the production product IDs:**

1. In Offerings → default
2. Add packages using:
   - **Premium Monthly** (hero.premium.monthly)
   - **Premium Yearly** (hero.premium.yearly)
   - **Premium Lifetime** (hero.premium.lifetime)

**Why?** Same product IDs work for both Test Store and Production. Test Store just uses sandbox purchases.

#### Option 2: Keep Test Store Products (Requires Code Change)

If you want to use the Test Store products (`monthly`, `yearly`, `lifetime`):

1. You'd need to update your app code to use different product IDs for DEBUG builds
2. Not recommended - adds complexity

#### Option 3: Delete Test Store Products, Use Production

1. Delete the Test Store products (`monthly`, `yearly`, `lifetime`)
2. Use only the production products (`hero.premium.monthly`, etc.)
3. They work for both Test Store and Production

---

## Recommended Setup

### For Test Store Offering:

**Use Production Products:**
- Package "Monthly" → Product: **Premium Monthly** (hero.premium.monthly)
- Package "Yearly" → Product: **Premium Yearly** (hero.premium.yearly)
- Package "Lifetime" → Product: **Premium Lifetime** (hero.premium.lifetime)

**Why?**
- ✅ Same product IDs as your app code
- ✅ Works for both Test Store and Production
- ✅ No code changes needed
- ✅ Simpler setup

### You Can Delete Test Store Products:

The products `monthly`, `yearly`, `lifetime` are redundant. You can:
1. Detach them from the entitlement
2. Delete them
3. Use only the production products

---

## Step-by-Step: Recommended Fix

### 1. Clean Up (Optional)

1. Go to **Products**
2. For each Test Store product (`monthly`, `yearly`, `lifetime`):
   - Click on it
   - Click **Detach** from Premium entitlement
   - Or just leave them (they won't hurt)

### 2. Create Offering with Packages

1. Go to **Offerings** → **default**
2. **Add Package 1:**
   - Identifier: `$rc_monthly`
   - Product: **Premium Monthly** (hero.premium.monthly)
   - Save
3. **Add Package 2:**
   - Identifier: `$rc_yearly`
   - Product: **Premium Yearly** (hero.premium.yearly)
   - Save
4. **Add Package 3:**
   - Identifier: `$rc_lifetime`
   - Product: **Premium Lifetime** (hero.premium.lifetime)
   - Save

### 3. Set Default Package

- Mark **Monthly** or **Yearly** as default

### 4. Test

Run your app - errors should be gone! ✅

---

## What You Should See After

**In Console:**
```
✅ RevenueCatService: Offerings loaded successfully
✅ RevenueCatService: Customer info updated - Premium: false
```

**No more errors!** 🎉

---

## Summary

**You have products ✅**  
**You need packages in your offering ❌**

**Quick fix:** Add 3 packages to your offering using the production products (hero.premium.monthly, etc.)

**Then:** Test again - should work! ✅
