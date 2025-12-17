# Superwall Placement Identifier - How to Set It Up

## The Issue

You're trying to set a placement identifier but "onboarding" doesn't appear in a list.

**This is normal!** Placement identifiers are usually **typed in manually**, not selected from a list.

---

## How Placement Identifiers Work

### Option 1: Type It Manually (Most Common)

1. In your campaign settings, find **Placement Identifier** field
2. It's usually a **text input field** (not a dropdown)
3. **Type:** `onboarding`
4. **Save**

### Option 2: Create Placement First (Some Versions)

Some Superwall dashboards require creating placements first:

1. Go to **Placements** or **Settings → Placements**
2. Click **+ New Placement**
3. **Identifier:** `onboarding`
4. **Name:** "Onboarding Paywall"
5. **Save**
6. Then select it in your campaign

### Option 3: It's Just a Text Field

The placement identifier is just a **string** you type:
- No list needed
- Just type what you want
- Use it in your app code

---

## Step-by-Step: Setting Up Placement

### Method 1: Direct Entry (Most Likely)

1. **Go to Campaigns** → Your campaign
2. **Find "Placement Identifier" field**
3. **Type:** `onboarding` (or any name you want)
4. **Save**

**That's it!** No list needed - just type it.

### Method 2: Create Placement First

1. **Go to Settings** → **Placements** (or similar)
2. **Click + New Placement**
3. **Identifier:** `onboarding`
4. **Description:** "Shown during onboarding"
5. **Save**
6. **Then in campaign**, select it from dropdown

---

## What Placement Identifier Does

The placement identifier is just a **name** you use in your app code:

```swift
// In your app code
SuperwallService.shared.presentPaywall(placement: "onboarding") {
    // This "onboarding" matches what you type in dashboard
}
```

**It's just a string - you can use any name!**

---

## Common Placement Names

You can use any of these (or make up your own):

- `onboarding`
- `feature_lock`
- `upgrade_prompt`
- `premium_screen`
- `paywall_main`
- `subscription_required`

**Just make sure:**
- ✅ Matches what you use in app code
- ✅ No spaces (use underscores)
- ✅ Lowercase recommended

---

## Where to Find Placement Field

### In Campaign Settings:

1. **Campaigns** → Your campaign
2. Look for:
   - "Placement Identifier"
   - "Placement"
   - "Identifier"
   - "Placement ID"
   - "Trigger Identifier"

### If You Can't Find It:

1. **Check campaign settings/configuration**
2. **Look for "Trigger" or "When to Show" section**
3. **Placement might be in trigger settings**

---

## Alternative: Use Default Placement

If you can't find placement settings:

1. **Just create the campaign**
2. **Don't worry about placement identifier**
3. **In your app code, use the campaign name or ID**

Some Superwall setups work without explicit placements.

---

## Quick Test

### 1. Create Campaign

1. Campaigns → + New Campaign
2. Name: "Onboarding Paywall"
3. **Placement Identifier:** Type `onboarding` (if field exists)
4. Save

### 2. Test in App

```swift
// Try this in your app
SuperwallService.shared.presentPaywall(placement: "onboarding")
```

If it doesn't work, try:
```swift
// Try without placement
Superwall.shared.register(placement: "onboarding") {
    // Feature
}
```

---

## Troubleshooting

### Issue: No Placement Field

**Solution:**
- Some Superwall versions don't require placements
- Just create campaign
- Use campaign name in app code

### Issue: Field Exists But Can't Type

**Solution:**
- Check if it's a dropdown (might need to create placement first)
- Or it might be auto-generated
- Try creating placement in Settings first

### Issue: Not Sure What to Type

**Solution:**
- Just type: `onboarding`
- Or: `main_paywall`
- Or: `premium`
- Any name works - just use same in app code!

---

## What Your App Code Needs

Your app code uses the placement like this:

```swift
// This "onboarding" must match what you type in dashboard
SuperwallService.shared.presentPaywall(placement: "onboarding")
```

**So whatever you type in dashboard, use the same in your code!**

---

## Summary

**Placement Identifier:**
- ✅ Usually a **text field** (type it in)
- ✅ Not a dropdown list
- ✅ Just type: `onboarding`
- ✅ Use same name in app code

**If you can't find the field:**
- ✅ Create campaign anyway
- ✅ Use campaign name in app code
- ✅ Or contact Superwall support

---

## Bottom Line

**Just type `onboarding` in the placement identifier field!**

It's not a list - it's a text input where you type whatever you want.

**Then use the same name in your app code!**

---

*Can you see a text field for "Placement Identifier" in your campaign settings? Just type "onboarding" there!*
