# ⚠️ IMPORTANT: Secret API Keys vs Public API Keys

## What You're Seeing

You're looking at **Secret API Keys** in your dashboard. These are **DIFFERENT** from the keys we're using in the app!

---

## Two Types of Keys

### 1. **Public API Keys** ✅ (What We Use in the App)

**Location in Dashboard:**
- RevenueCat: Project Settings → **API Keys** (Public section)
- Superwall: Settings → **API Keys** (Public section)

**Characteristics:**
- ✅ **Safe to put in client code** (iOS app)
- ✅ **Meant to be public** - they identify your project
- ✅ **Start with:** `appl_` (RevenueCat) or `pk_` (Superwall)
- ✅ **What we're using in AppConfig.swift**

**Example:**
```
appl_rcEmwNiUYUgSBkoXePHgjfKFjcI  ← Public key (safe for app)
pk_FkOPYHsQH06fg63Xr0lTU          ← Public key (safe for app)
```

---

### 2. **Secret API Keys** ⚠️ (DO NOT Use in App!)

**Location in Dashboard:**
- RevenueCat: Project Settings → **API Keys** → **Secret API Keys** section
- Superwall: Settings → **API Keys** → **Secret Keys** section

**Characteristics:**
- ❌ **NEVER put in client code** (iOS app)
- ❌ **NEVER commit to GitHub**
- ❌ **Only for server-side** operations
- ❌ **Start with:** `sk_` (Secret Key)
- ❌ **Used for:** Backend API calls, webhooks, admin operations

**Example:**
```
sk_abc123xyz...  ← Secret key (NEVER put in app!)
```

---

## What You Should Do

### ✅ CORRECT: Use Public Keys in App

**In AppConfig.swift, you should have:**
```swift
// ✅ CORRECT - Public key (safe)
return "appl_rcEmwNiUYUgSBkoXePHgjfKFjcI"  // Public key
return "pk_FkOPYHsQH06fg63Xr0lTU"          // Public key
```

### ❌ WRONG: Never Use Secret Keys in App

```swift
// ❌ WRONG - Secret key (NEVER do this!)
return "sk_abc123xyz..."  // Secret key - DO NOT USE!
```

---

## How to Find Your Public Keys

### RevenueCat:
1. Go to: https://app.revenuecat.com
2. Your Project → **Project Settings** → **API Keys**
3. Look for **"Public API Key"** section (NOT Secret API Keys)
4. Copy the key that starts with `appl_` or `pk_`

### Superwall:
1. Go to: https://superwall.com/dashboard
2. **Settings** → **API Keys**
3. Look for **"Public API Key"** (NOT Secret Keys)
4. Copy the key that starts with `pk_`

---

## When to Use Secret Keys

**Secret keys are ONLY for:**
- ✅ Server-side applications (backend)
- ✅ Webhook endpoints
- ✅ Admin operations
- ✅ Server-to-server API calls

**Secret keys are NEVER for:**
- ❌ iOS apps
- ❌ Client-side code
- ❌ Public repositories
- ❌ Frontend applications

---

## Current Status Check

### Check Your AppConfig.swift:

**✅ If you see keys starting with:**
- `appl_` (RevenueCat) → ✅ Correct (Public key)
- `pk_` (Superwall) → ✅ Correct (Public key)

**❌ If you see keys starting with:**
- `sk_` → ❌ WRONG! Replace with public key immediately!

---

## What the Dashboard Shows

When you see:
```
API keys
Secret API keys
Generate secret API keys...
```

This means:
- You're looking at the **Secret Keys** section
- These are **NOT** what goes in your app
- You need to find the **Public API Keys** section instead

---

## Quick Checklist

- [ ] I found the **Public API Key** section (not Secret)
- [ ] My keys in AppConfig.swift start with `appl_` or `pk_`
- [ ] I did NOT use any keys starting with `sk_`
- [ ] I understand secret keys are only for server-side

---

## Summary

| Key Type | Use In App? | Starts With | Purpose |
|----------|-------------|-------------|---------|
| **Public** | ✅ YES | `appl_`, `pk_` | Client apps (iOS) |
| **Secret** | ❌ NO | `sk_` | Server-side only |

**Your app should ONLY use Public API Keys!**

---

*If you accidentally put a secret key in your app, replace it with a public key immediately!*
