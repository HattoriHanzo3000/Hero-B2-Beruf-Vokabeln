# Superwall Custom Event - How to Create One

## The Issue

You see a dropdown with system events like:
- `config_attributes`
- `config_refresh`
- `session_start`
- etc.

But you need a **custom event** like `onboarding`.

---

## Solution: Create Custom Event First

### Step 1: Create Custom Event

1. **Look for "Events" or "Custom Events" section**
   - Might be in **Settings → Events**
   - Or **Project Settings → Events**
   - Or **Analytics → Events**

2. **Click "+ New Event" or "Create Event"**

3. **Event Name:** Type `onboarding`
   - Or any name you want
   - No spaces (use underscores)

4. **Save**

### Step 2: Select It in Campaign

1. **Go back to your campaign**
2. **In the dropdown**, your custom event should now appear
3. **Select:** `onboarding`
4. **Save**

---

## Alternative: Use Existing Event

If you can't create custom events, use an existing one:

### Option 1: Use `session_start`

1. **Select:** `session_start` from dropdown
2. **Configure:** "Show after X sessions"
3. **In your app code:**
   ```swift
   // This will trigger automatically on session start
   // Or trigger manually:
   Superwall.shared.track("session_start")
   ```

### Option 2: Use `app_launch`

1. **Select:** `app_launch` from dropdown
2. **Configure:** "Show after X app launches"
3. **Works automatically**

---

## Where to Create Custom Event

### Look For:

1. **Settings → Events**
2. **Project Settings → Custom Events**
3. **Analytics → Events → + New**
4. **Campaigns → Events** (might be a tab)
5. **Sidebar → Events**

### If You Can't Find It:

Some Superwall plans might not allow custom events. In that case:

**Use an existing event** and trigger it from your code:

```swift
// Use session_start
Superwall.shared.track("session_start")

// Or use app_launch
Superwall.shared.track("app_launch")
```

---

## Quick Workaround

### If You Can't Create Custom Event:

1. **Select any event** from dropdown (like `session_start`)
2. **In your app code, trigger it when you want:**
   ```swift
   // When you want to show paywall
   SuperwallService.shared.presentPaywall(placement: "onboarding")
   
   // Or track the event
   Superwall.shared.track("session_start")
   ```

**The placement identifier (`onboarding`) is separate from the event!**

---

## Understanding the Difference

### Event (What You're Selecting):
- **System events:** `session_start`, `app_launch`, etc.
- **Custom events:** `onboarding` (if you create it)
- **Purpose:** Tells Superwall WHEN to show paywall

### Placement Identifier:
- **Separate field:** Usually called "Placement" or "Identifier"
- **What you type:** `onboarding`
- **Purpose:** Name you use in app code

**You might have BOTH:**
- **Event:** `session_start` (from dropdown)
- **Placement:** `onboarding` (text field)

---

## Recommended Setup

### Option 1: Create Custom Event (Best)

1. **Settings → Events → + New Event**
2. **Name:** `onboarding`
3. **Save**
4. **In campaign, select:** `onboarding` from dropdown
5. **In app code:**
   ```swift
   Superwall.shared.track("onboarding")
   ```

### Option 2: Use System Event (Easier)

1. **In campaign, select:** `session_start` from dropdown
2. **Configure:** "Show after 1 session" (or your preference)
3. **In app code:**
   ```swift
   // Trigger manually when you want
   Superwall.shared.track("session_start")
   // Or it triggers automatically
   ```

### Option 3: Just Use Placement (Simplest)

1. **Select any event** from dropdown (doesn't matter which)
2. **Find "Placement Identifier" field** (separate field)
3. **Type:** `onboarding`
4. **In app code:**
   ```swift
   SuperwallService.shared.presentPaywall(placement: "onboarding")
   ```

---

## What to Do Right Now

### Quickest Solution:

1. **Select:** `session_start` from dropdown
2. **Look for separate "Placement" field** - type `onboarding` there
3. **Save**
4. **In your app:**
   ```swift
   SuperwallService.shared.presentPaywall(placement: "onboarding")
   ```

**The event doesn't matter if you're calling `presentPaywall` directly!**

---

## Check Your Campaign Settings

Look for **TWO separate fields**:

1. **Event/Trigger:** Dropdown (select `session_start` or any)
2. **Placement Identifier:** Text field (type `onboarding`)

**The placement is what matters for your code!**

---

## Summary

**What you're seeing:**
- ✅ Dropdown with system events (normal)

**What to do:**
1. **Select any event** from dropdown (like `session_start`)
2. **OR create custom event** in Settings → Events
3. **Find "Placement" field** - type `onboarding` there
4. **Use placement in app code** - that's what matters!

**The event is just the trigger - placement is what you use in code!**

---

*Select any event from dropdown, then look for a separate "Placement" or "Identifier" field where you can type `onboarding`!*
