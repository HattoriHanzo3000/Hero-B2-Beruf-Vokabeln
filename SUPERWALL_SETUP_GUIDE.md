# Superwall Setup Guide

## What You Need from Superwall Dashboard

To complete the Superwall integration, you need **one essential piece of information**:

### 1. **Superwall API Key** (Required)

**Where to find it:**
1. Go to [Superwall Dashboard](https://superwall.com/dashboard)
2. Navigate to **Settings** → **API Keys**
3. Copy your **API Key** (it looks like: `pk_live_...` or `pk_test_...`)

**What to do with it:**
- Open `SuperwallService.swift`
- Replace `"YOUR_SUPERWALL_API_KEY_HERE"` on **line 35** (for DEBUG) and **line 38** (for Release) with your actual API key

**Example:**
```swift
private let apiKey: String = {
    #if DEBUG
    return "pk_test_abc123xyz..."  // Your test/sandbox API key
    #else
    return "pk_live_def456uvw..."  // Your production API key
    #endif
}()
```

---

## Optional: Superwall Dashboard Configuration

While the API key is the only **required** information, you may want to configure these in the Superwall dashboard:

### 2. **Paywall Configuration** (Optional)
- Create paywalls in Superwall Dashboard → **Paywalls**
- Set up paywall designs and copy
- Configure which products to show

### 3. **Event Triggers** (Optional)
- Set up events in Superwall Dashboard → **Events**
- Configure when paywalls should appear
- Example events: `premium_feature_accessed`, `trial_ended`, etc.

### 4. **Products** (Already handled by RevenueCat)
- **Note:** Products are managed in **RevenueCat**, not Superwall
- Superwall will automatically use products from RevenueCat via the `RevenueCatPurchaseController`

---

## Current Integration Status

✅ **Already Configured:**
- SuperwallKit package is installed
- `SuperwallService` is initialized in `B2_BerufssprachkursApp.swift`
- RevenueCat integration is set up via `RevenueCatPurchaseController`
- Subscription status syncing is implemented

⚠️ **Needs Your Input:**
- **Superwall API Key** - Replace placeholder in `SuperwallService.swift`

---

## Testing Without API Key

The app will still compile and run without the API key, but:
- Superwall will not initialize
- Paywalls will not appear
- You'll see a warning: `"⚠️ SuperwallService: API key not configured"`

---

## Next Steps

1. **Get your Superwall API Key** from the dashboard
2. **Add it to `SuperwallService.swift`** (lines 35 & 38)
3. **Test the integration** - The service will automatically configure when the app launches
4. **Create paywalls** in Superwall Dashboard (optional, for custom designs)

---

## Integration Architecture

```
App Launch
    ↓
RevenueCatService.shared (initializes first)
    ↓
SuperwallService.shared.configure() (waits for RevenueCat)
    ↓
Superwall.configure(apiKey, purchaseController)
    ↓
RevenueCatPurchaseController handles all purchases
    ↓
Subscription status syncs between RevenueCat ↔ Superwall
```

---

## Support

- **Superwall Docs:** https://superwall.com/docs
- **Superwall Dashboard:** https://superwall.com/dashboard
- **RevenueCat Integration:** Already configured ✅

---

**Summary:** You only need **one thing** - your Superwall API Key from the dashboard. Everything else is already integrated!
