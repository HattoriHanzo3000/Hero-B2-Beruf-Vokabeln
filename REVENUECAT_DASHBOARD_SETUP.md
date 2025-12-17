# RevenueCat Dashboard Setup Guide

Complete step-by-step guide to configure products, entitlements, and API keys in RevenueCat.

## 📋 Prerequisites

- RevenueCat account (sign up at https://app.revenuecat.com)
- App Store Connect account with your app configured
- Product IDs ready from App Store Connect

---

## Step 1: Get Your RevenueCat API Key

### 1.1 Navigate to API Keys
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Sign in to your account
3. Select your **Project** (or create a new one)
4. Go to **Project Settings** → **API Keys**

### 1.2 Copy Your API Keys
You'll see two keys:
- **Public API Key** (starts with `pk_`) - Use this in your app
- **Secret API Key** (starts with `sk_`) - Keep this secret, never commit to code

**For your app:**
- **Public API Key**: `pk_a1ff69eaf4ea6e199bcabdcfbd17d39fc8679f426b8f2ca5` (already configured in `RevenueCatService.swift`)

---

## Step 2: Configure Products

### 2.1 Add Products to RevenueCat
1. In RevenueCat Dashboard, go to **Products**
2. Click **+ Add Product** or **Add Product from App Store Connect**

### 2.2 Your Product IDs (from your code):
Based on `RevenueCatService.swift` and `SubscriptionManager.swift`, you need to add these products:

```
hero.premium.monthly
hero.premium.yearly
hero.premium.lifetime
monthly          (alternative)
yearly           (alternative)
lifetime         (alternative)
```

### 2.3 Add Each Product:
1. Click **+ Add Product**
2. Enter the **Product Identifier** (e.g., `hero.premium.monthly`)
3. Select **Product Type**: 
   - `hero.premium.monthly` → **Subscription** (Monthly)
   - `hero.premium.yearly` → **Subscription** (Annual)
   - `hero.premium.lifetime` → **Non-Consumable** or **Non-Renewing Subscription**
4. Click **Save**

### 2.4 Link to App Store Connect
- If products already exist in App Store Connect, RevenueCat will automatically link them
- If not, you'll need to create them in App Store Connect first, then link in RevenueCat

---

## Step 3: Create Entitlements

### 3.1 Create Premium Entitlement
1. Go to **Entitlements** in RevenueCat Dashboard
2. Click **+ New Entitlement**
3. Enter:
   - **Identifier**: `premium` (must match your code!)
   - **Display Name**: "Premium Access" (or any name you prefer)
4. Click **Save**

### 3.2 Attach Products to Entitlement
1. Click on the `premium` entitlement you just created
2. Under **Products**, click **+ Attach Product**
3. Select all your subscription products:
   - `hero.premium.monthly`
   - `hero.premium.yearly`
   - `hero.premium.lifetime`
   - `monthly` (if using)
   - `yearly` (if using)
   - `lifetime` (if using)
4. Click **Save**

**Important**: All products that grant premium access must be attached to the `premium` entitlement.

---

## Step 4: Create Offerings

### 4.1 Create Default Offering
1. Go to **Offerings** in RevenueCat Dashboard
2. Click **+ New Offering**
3. Enter:
   - **Identifier**: Leave as "default" (or create custom identifier)
   - **Display Name**: "Premium Subscription"
4. Click **Save**

### 4.2 Add Packages to Offering
1. Click on your offering
2. Under **Packages**, click **+ Add Package**
3. For each subscription tier, create a package:
   
   **Package 1: Monthly**
   - **Identifier**: `monthly` (or `$rc_monthly`)
   - **Product**: Select `hero.premium.monthly`
   - **Display Name**: "Monthly"
   
   **Package 2: Yearly**
   - **Identifier**: `yearly` (or `$rc_yearly`)
   - **Product**: Select `hero.premium.yearly`
   - **Display Name**: "Yearly"
   
   **Package 3: Lifetime**
   - **Identifier**: `lifetime` (or `$rc_lifetime`)
   - **Product**: Select `hero.premium.lifetime`
   - **Display Name**: "Lifetime"

4. **Set as Default Offering**: Make sure this offering is marked as "default" (it will be used automatically)

---

## Step 5: Configure Promotional Pricing (Optional)

### 5.1 Set Up Promotional Offers in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → **Subscriptions**
3. Select a subscription (e.g., `hero.premium.monthly`)
4. Go to **Promotional Offers**
5. Click **+ Create Promotional Offer**
6. Configure:
   - **Reference Name**: e.g., "Introductory Offer"
   - **Duration**: e.g., 1 month
   - **Type**: Free trial, Pay as you go, or Pay up front
   - **Price**: Set promotional price
7. Click **Create**

### 5.2 Configure in RevenueCat
1. In RevenueCat Dashboard, go to **Products**
2. Click on the product (e.g., `hero.premium.monthly`)
3. Under **Promotional Offers**, you'll see offers from App Store Connect
4. RevenueCat automatically syncs promotional offers from App Store Connect

### 5.3 Use Promotional Offers in Code
Promotional offers are automatically available when users purchase. RevenueCat handles them automatically.

---

## Step 6: Configure Superwall Integration (Optional)

### 6.1 Link RevenueCat to Superwall
1. In RevenueCat Dashboard, go to **Project Settings** → **Integrations**
2. Find **Superwall** in the list
3. Click **Connect** or **Configure**
4. Enter your **Superwall Public API Key**: `pk_FkOPYHsQH06fg63Xr0lTU`
5. Click **Save**

This enables RevenueCat to automatically forward purchase/renewal events to Superwall.

---

## Step 7: Verify Configuration

### 7.1 Check Your Setup
✅ **API Key**: Configured in `RevenueCatService.swift`  
✅ **Products**: All product IDs added to RevenueCat  
✅ **Entitlement**: `premium` entitlement created  
✅ **Products Attached**: All products attached to `premium` entitlement  
✅ **Offering**: Default offering created with packages  
✅ **Superwall Integration**: Connected (if using Superwall)

### 7.2 Test in Your App
1. Run your app
2. Check console logs for:
   - `✅ RevenueCatService: SDK initialized successfully`
   - `✅ RevenueCatService: Offerings loaded successfully`
3. Try loading the paywall - products should appear

---

## 📝 Quick Reference

### Your Current Configuration (from code):

**API Key:**
```
pk_a1ff69eaf4ea6e199bcabdcfbd17d39fc8679f426b8f2ca5
```

**Product IDs:**
- `hero.premium.monthly`
- `hero.premium.yearly`
- `hero.premium.lifetime`
- `monthly` (alternative)
- `yearly` (alternative)
- `lifetime` (alternative)

**Entitlement ID:**
```
premium
```

**Superwall API Key:**
```
pk_FkOPYHsQH06fg63Xr0lTU
```

---

## 🚨 Common Issues & Solutions

### Issue: "No offerings available"
**Solution**: 
- Make sure you created an offering and marked it as "default"
- Verify packages are added to the offering
- Check that products are linked to the entitlement

### Issue: "Product not found"
**Solution**:
- Verify product IDs match exactly between App Store Connect and RevenueCat
- Ensure products are approved in App Store Connect
- Check that products are attached to the entitlement

### Issue: "Entitlement not active after purchase"
**Solution**:
- Verify the product is attached to the `premium` entitlement
- Check that the entitlement identifier matches: `premium`
- Ensure the purchase completed successfully

---

## 📚 Additional Resources

- [RevenueCat Documentation](https://www.revenuecat.com/docs)
- [RevenueCat Dashboard](https://app.revenuecat.com)
- [App Store Connect](https://appstoreconnect.apple.com)

---

## ✅ Checklist

- [ ] API Key copied and configured in code
- [ ] All products added to RevenueCat
- [ ] Products linked to App Store Connect
- [ ] `premium` entitlement created
- [ ] All products attached to `premium` entitlement
- [ ] Default offering created
- [ ] Packages added to offering
- [ ] Superwall integration configured (if using)
- [ ] Tested in app - offerings load successfully

---

**Need Help?** Check the RevenueCat documentation or contact RevenueCat support through the dashboard.
