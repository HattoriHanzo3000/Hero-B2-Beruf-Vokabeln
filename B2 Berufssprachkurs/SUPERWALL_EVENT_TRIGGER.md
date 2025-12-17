# Superwall In-App Event Trigger Setup

## What Superwall is Asking For

Superwall wants to know **what event** triggers your paywall to appear.

This is the **trigger** - when should the paywall show?

---

## Common Event Options

### Option 1: App Launch / Session Start

**Event:** `app_launch` or `session_start`
- Shows paywall when app launches
- Or after X app opens

### Option 2: Custom Event (Recommended)

**Event:** `onboarding` or `show_paywall`
- You trigger this from your app code
- More control over when paywall appears

### Option 3: Feature Access

**Event:** `premium_feature_accessed`
- Shows when user tries to access premium feature
- You trigger from your app code

---

## How to Set It Up

### Step 1: Choose Event Type

In Superwall dashboard, you'll see options like:

1. **App Launch** - Shows on app open
2. **Custom Event** - You trigger from code
3. **Feature Access** - Shows when accessing feature
4. **Time-Based** - Shows after X days

### Step 2: For Custom Event (Recommended)

1. **Select:** "Custom Event" or "In-App Event"
2. **Event Name:** Type `onboarding` (or any name)
3. **Save**

### Step 3: Use in Your App Code

```swift
// Track the event to trigger paywall
Superwall.shared.track("onboarding")

// Or use your service
SuperwallService.shared.presentPaywall(placement: "onboarding")
```

---

## Quick Setup Guide

### Method 1: Custom Event (Best Control)

1. **In Superwall Dashboard:**
   - Select "Custom Event" or "In-App Event"
   - **Event Name:** `onboarding`
   - Save

2. **In Your App Code:**
   ```swift
   // Trigger the event
   Superwall.shared.track("onboarding")
   
   // Or present paywall directly
   SuperwallService.shared.presentPaywall(placement: "onboarding")
   ```

### Method 2: App Launch (Simplest)

1. **In Superwall Dashboard:**
   - Select "App Launch" or "Session Start"
   - Configure: "Show after X app opens"
   - Save

2. **No code needed** - Superwall handles it automatically

### Method 3: Feature Access

1. **In Superwall Dashboard:**
   - Select "Feature Access" or "Premium Feature"
   - **Event Name:** `premium_feature_accessed`
   - Save

2. **In Your App Code:**
   ```swift
   // When user tries to access premium feature
   if !RevenueCatService.shared.isPremiumActive {
       Superwall.shared.track("premium_feature_accessed")
   }
   ```

---

## What to Type in "In App Event" Field

**Type one of these:**

- `onboarding` - For onboarding paywall
- `show_paywall` - Generic paywall trigger
- `premium_required` - When premium needed
- `upgrade_prompt` - Upgrade prompt
- `feature_lock` - Feature is locked

**Or make up your own:**
- Any name works!
- Just use same name in app code

---

## Complete Example

### In Superwall Dashboard:

1. **Campaign Name:** "Onboarding Paywall"
2. **Trigger Type:** "Custom Event" or "In-App Event"
3. **Event Name:** `onboarding`
4. **Save**

### In Your App Code:

```swift
// Option 1: Track event (triggers paywall automatically)
Superwall.shared.track("onboarding")

// Option 2: Present paywall directly
SuperwallService.shared.presentPaywall(placement: "onboarding") {
    // User subscribed or dismissed
    print("Paywall completed")
}
```

---

## Common Event Names

You can use any of these event names:

| Event Name | When to Use |
|------------|-------------|
| `onboarding` | During app onboarding |
| `premium_required` | When premium feature accessed |
| `upgrade_prompt` | General upgrade prompt |
| `feature_lock` | When feature is locked |
| `app_launch` | On app launch |
| `session_start` | When session starts |

---

## If You're Not Sure

### Simplest Option:

1. **Event Name:** Type `onboarding`
2. **Save**
3. **In your app code:**
   ```swift
   SuperwallService.shared.presentPaywall(placement: "onboarding")
   ```

**This will work!**

---

## Troubleshooting

### Issue: Event Not Triggering Paywall

**Solution:**
- Make sure event name matches exactly
- Check campaign is active
- Verify paywall is designed and saved

### Issue: Don't Know What Event to Use

**Solution:**
- Just use: `onboarding`
- Or: `show_paywall`
- Any name works - just use same in code!

### Issue: Want Multiple Triggers

**Solution:**
- Create multiple campaigns
- Each with different event name
- Trigger different events from code

---

## Summary

**What Superwall is asking:**
- ✅ What event triggers the paywall?

**What to do:**
1. **Select:** "Custom Event" or "In-App Event"
2. **Type:** `onboarding` (or any name)
3. **Save**

**In your app:**
```swift
SuperwallService.shared.presentPaywall(placement: "onboarding")
```

---

## Bottom Line

**Just type `onboarding` in the "In App Event" field!**

Then use the same name in your app code when you want to show the paywall.

**That's it!** 🚀

---

*Type "onboarding" in the event field, save, and you're done!*
