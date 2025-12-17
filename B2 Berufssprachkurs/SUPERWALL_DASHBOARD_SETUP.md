# Superwall Dashboard Setup Guide

Complete step-by-step guide to connect Superwall to RevenueCat and configure paywall triggers.

---

## Step 1: Connect Superwall to RevenueCat

### 1.1 Go to Superwall Dashboard

1. Go to: https://superwall.com/dashboard
2. Sign in to your account

### 1.2 Navigate to Integrations

1. Click on **Settings** (gear icon, usually in top right or sidebar)
2. Go to **Integrations** section
3. Look for **RevenueCat** integration

### 1.3 Connect RevenueCat

1. Find **RevenueCat** in the integrations list
2. Click **Connect** or **Configure**
3. You'll need your **RevenueCat Public API Key**:
   - Go to: https://app.revenuecat.com
   - Your Project → **Project Settings** → **API Keys**
   - Copy your **Public API Key**: `appl_rcEmwNiUYUgSBkoXePHgjfKFjcI`
4. Paste the API key into Superwall
5. Click **Save** or **Connect**

### 1.4 Verify Connection

- You should see a green checkmark or "Connected" status
- Superwall will now receive purchase events from RevenueCat

---

## Step 2: Create Paywall Campaigns

### 2.1 Navigate to Campaigns

1. In Superwall Dashboard, go to **Campaigns**
2. Click **+ New Campaign** or **Create Campaign**

### 2.2 Create Your First Campaign

#### Campaign 1: Onboarding Paywall

1. **Campaign Name:** "Onboarding Paywall"
2. **Campaign Type:** Choose appropriate type (usually "Paywall")
3. **Placement Identifier:** `onboarding`
   - This is what you'll use in your app code
4. **Trigger:** When to show this paywall
   - Example: "After 3 app opens"
   - Or: "When accessing premium feature"
5. **Save**

#### Campaign 2: Feature Lock Paywall (Optional)

1. **Campaign Name:** "Feature Lock Paywall"
2. **Placement Identifier:** `feature_lock`
3. **Trigger:** "When user tries to access locked feature"
4. **Save**

#### Campaign 3: Upgrade Prompt (Optional)

1. **Campaign Name:** "Upgrade Prompt"
2. **Placement Identifier:** `upgrade_prompt`
3. **Trigger:** "After user dismisses paywall 2 times"
4. **Save**

---

## Step 3: Design Your Paywall

### 3.1 Create Paywall Design

1. In your campaign, click **Design Paywall** or **Create Paywall**
2. Choose a template or start from scratch
3. Design your paywall:
   - Add your app branding
   - Add product options (Monthly, Yearly, Lifetime)
   - Add benefits/features list
   - Customize colors, fonts, layout

### 3.2 Link Products

1. In the paywall designer, find **Products** section
2. Link to your RevenueCat products:
   - **Monthly:** Should auto-sync from RevenueCat
   - **Yearly:** Should auto-sync from RevenueCat
   - **Lifetime:** Should auto-sync from RevenueCat
3. Products should appear automatically if RevenueCat is connected

### 3.3 Configure Purchase Flow

1. Set up purchase button actions
2. Configure restore purchases button
3. Set up close/dismiss behavior
4. **Save** your paywall design

---

## Step 4: Configure Paywall Triggers

### 4.1 Set Up Triggers in Campaign

1. Go back to your campaign settings
2. Find **Triggers** or **When to Show** section
3. Configure when paywall should appear:

#### Common Trigger Options:

**Option 1: App Opens**
- Show after X app opens
- Example: "Show after 3 app opens"

**Option 2: Feature Access**
- Show when user tries to access premium feature
- You'll trigger this from your app code

**Option 3: Time-Based**
- Show after X days since install
- Example: "Show after 7 days"

**Option 4: Custom Event**
- Trigger from your app code
- Example: "User tapped premium button"

### 4.2 Frequency Capping

1. Set how often paywall can appear:
   - **Max per day:** 3 times
   - **Max per week:** 10 times
   - **Cooldown:** 24 hours between shows

2. This prevents showing paywall too often

---

## Step 5: Test Your Setup

### 5.1 Test in App

1. **Run your app**
2. **Trigger the paywall** (based on your trigger settings)
3. **Verify:**
   - Paywall appears
   - Products show correctly
   - Prices display correctly
   - Purchase button works

### 5.2 Test Purchase Flow

1. **Tap purchase button**
2. **Complete test purchase** (sandbox account)
3. **Verify:**
   - Purchase completes
   - Premium access granted
   - Paywall dismisses
   - Events appear in Superwall dashboard

---

## Step 6: Use Paywalls in Your App Code

### 6.1 Basic Usage

Your app already has Superwall integrated! You can trigger paywalls like this:

```swift
// Trigger paywall by placement identifier
SuperwallService.shared.presentPaywall(placement: "onboarding") {
    // This closure runs if user subscribes or dismisses
    print("Paywall dismissed or purchase completed")
}
```

### 6.2 Common Placements

```swift
// Onboarding paywall
SuperwallService.shared.presentPaywall(placement: "onboarding")

// Feature lock paywall
SuperwallService.shared.presentPaywall(placement: "feature_lock")

// Upgrade prompt
SuperwallService.shared.presentPaywall(placement: "upgrade_prompt")
```

### 6.3 Register Placement (Alternative)

```swift
// Register placement that triggers automatically
SuperwallService.shared.register(placement: "onboarding") {
    // Feature to unlock
    unlockPremiumFeature()
}
```

---

## Quick Setup Checklist

### RevenueCat Connection
- [ ] Go to Superwall Dashboard → Settings → Integrations
- [ ] Find RevenueCat integration
- [ ] Add RevenueCat Public API Key: `appl_rcEmwNiUYUgSBkoXePHgjfKFjcI`
- [ ] Verify connection status shows "Connected"

### Campaign Setup
- [ ] Create campaign: "Onboarding Paywall"
- [ ] Set placement identifier: `onboarding`
- [ ] Configure trigger (when to show)
- [ ] Set frequency capping

### Paywall Design
- [ ] Design paywall (or use template)
- [ ] Link products (should auto-sync from RevenueCat)
- [ ] Customize design (colors, fonts, layout)
- [ ] Configure purchase buttons
- [ ] Save paywall

### Testing
- [ ] Test paywall appears in app
- [ ] Test purchase flow
- [ ] Verify events in Superwall dashboard
- [ ] Verify events in RevenueCat dashboard

---

## Troubleshooting

### Products Not Showing in Paywall

**Issue:** Products don't appear in paywall designer

**Fix:**
1. Verify RevenueCat connection is active
2. Check products exist in RevenueCat dashboard
3. Wait a few minutes for sync
4. Refresh paywall designer

### Paywall Not Appearing

**Issue:** Paywall doesn't show when triggered

**Fix:**
1. Check placement identifier matches exactly
2. Verify campaign is active (not archived)
3. Check frequency capping (might be too restrictive)
4. Verify Superwall API key is correct in app

### Purchase Events Not Syncing

**Issue:** Purchases not showing in Superwall dashboard

**Fix:**
1. Verify RevenueCat connection is active
2. Check RevenueCat dashboard shows purchases
3. Wait a few minutes for event sync
4. Check Superwall dashboard → Events tab

---

## Advanced Configuration

### A/B Testing

1. Create multiple paywall variants
2. Set traffic distribution (50/50, etc.)
3. Superwall will automatically test which performs better

### Analytics

1. Go to **Analytics** in Superwall dashboard
2. View:
   - Paywall impressions
   - Conversion rates
   - Revenue per user
   - Best performing paywalls

### Custom Events

You can trigger paywalls from custom events:

```swift
// Track custom event
Superwall.shared.track("user_viewed_premium_feature")

// Then set up trigger in Superwall dashboard
// to show paywall when this event fires
```

---

## Summary

**What You Need to Do:**

1. ✅ **Connect Superwall to RevenueCat** (5 minutes)
   - Settings → Integrations → RevenueCat
   - Add API key: `appl_rcEmwNiUYUgSBkoXePHgjfKFjcI`

2. ✅ **Create Campaign** (10 minutes)
   - Campaigns → New Campaign
   - Name: "Onboarding Paywall"
   - Placement: `onboarding`
   - Set trigger

3. ✅ **Design Paywall** (15-30 minutes)
   - Use template or custom design
   - Products should auto-sync
   - Customize appearance

4. ✅ **Test** (5 minutes)
   - Run app
   - Trigger paywall
   - Test purchase

**Total Time:** ~30-45 minutes

---

*Your app code is already set up! Just configure the dashboard and you're done!* 🚀
