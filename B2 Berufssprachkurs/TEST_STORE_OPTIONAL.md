# Test Store: Optional or Required?

## Quick Answer

**✅ YES, you can skip Test Store entirely!**

You can use the **production key** for both DEBUG and RELEASE builds. Many apps do this.

---

## What is Test Store?

**Test Store** is a separate environment in RevenueCat that:
- Uses sandbox/test purchases (free testing)
- Keeps test data separate from production
- Doesn't affect real customer data
- Useful for development and testing

**But it's NOT required!**

---

## Two Approaches

### Approach 1: Use Test Store (What You Have Now)

**DEBUG builds:** Test Store key (`test_awDtpFpEwzXmwXUfynkCRiBrIuD`)  
**RELEASE builds:** Production key (`appl_rcEmwNiUYUgSBkoXePHgjfKFjcI`)

**Pros:**
- ✅ Test purchases don't mix with production data
- ✅ Safe testing environment
- ✅ Can test without affecting real customers

**Cons:**
- ❌ Need to set up products in both environments
- ❌ More configuration
- ❌ More complexity

---

### Approach 2: Skip Test Store (Simpler!)

**DEBUG builds:** Production key (`appl_rcEmwNiUYUgSBkoXePHgjfKFjcI`)  
**RELEASE builds:** Production key (`appl_rcEmwNiUYUgSBkoXePHgjfKFjcI`)

**Pros:**
- ✅ Simpler setup (one environment)
- ✅ Less configuration
- ✅ Same products everywhere
- ✅ Still uses sandbox purchases for testing (Apple handles this)

**Cons:**
- ⚠️ Test purchases show in production dashboard (but marked as sandbox)
- ⚠️ Need to filter test data in dashboard

---

## How to Skip Test Store

### Option 1: Use Production Key for Everything

**Update AppConfig.swift:**

```swift
static var revenueCatAPIKey: String {
    // ... Info.plist and environment variable checks ...
    
    #if DEBUG
    // Use production key for testing too
    return "appl_rcEmwNiUYUgSBkoXePHgjfKFjcI"  // Production key
    #else
    // Production key for release
    return "appl_rcEmwNiUYUgSBkoXePHgjfKFjcI"  // Production key
    #endif
}
```

**Or even simpler:**

```swift
static var revenueCatAPIKey: String {
    // ... Info.plist and environment variable checks ...
    
    // Use production key for both DEBUG and RELEASE
    return "appl_rcEmwNiUYUgSBkoXePHgjfKFjcI"
}
```

### Option 2: Keep Test Store (Current Setup)

Keep your current setup if you want separate test environment.

---

## How Testing Works Without Test Store

**Even with production key, testing is safe:**

1. **Sandbox Accounts:** Apple uses sandbox accounts for testing
2. **Sandbox Purchases:** All test purchases are marked as sandbox
3. **No Real Charges:** Sandbox purchases don't charge real money
4. **Separate in Dashboard:** RevenueCat marks sandbox purchases differently

**You can test safely with production key!**

---

## Recommendation

### For Most Apps: Skip Test Store ✅

**Use production key for both DEBUG and RELEASE:**

- ✅ Simpler
- ✅ Less configuration
- ✅ Still safe for testing (sandbox)
- ✅ One environment to manage

### Use Test Store If:

- You have a large team
- You want completely separate test data
- You're doing extensive testing
- You want to test without any production data

---

## How to Switch

### Step 1: Update AppConfig.swift

Change this:
```swift
#if DEBUG
return "test_awDtpFpEwzXmwXUfynkCRiBrIuD"  // Test Store
#else
return "appl_rcEmwNiUYUgSBkoXePHgjfKFjcI"  // Production
#endif
```

To this:
```swift
#if DEBUG
return "appl_rcEmwNiUYUgSBkoXePHgjfKFjcI"  // Production (for testing)
#else
return "appl_rcEmwNiUYUgSBkoXePHgjfKFjcI"  // Production
#endif
```

Or even simpler:
```swift
// Use production key for everything
return "appl_rcEmwNiUYUgSBkoXePHgjfKFjcI"
```

### Step 2: Set Up Production Dashboard Only

1. Go to RevenueCat Dashboard
2. Use **Production** key environment
3. Set up:
   - Entitlement: `premium`
   - Products: `hero.premium.monthly`, `hero.premium.yearly`, `hero.premium.lifetime`
   - Offering: `default` with 3 packages
4. **Done!** No Test Store setup needed

### Step 3: Test

- Run app in DEBUG mode
- Uses production key
- Sandbox purchases work (Apple handles this)
- Test purchases show in dashboard (marked as sandbox)

---

## Summary

| Question | Answer |
|----------|--------|
| **Do I need Test Store?** | ❌ No, it's optional |
| **Can I skip it?** | ✅ Yes, use production key for both |
| **Is it safe to test with production key?** | ✅ Yes, Apple uses sandbox |
| **Which is simpler?** | ✅ Skip Test Store |
| **Which is better?** | 🤷 Depends on your needs |

---

## Bottom Line

**Test Store is optional!**

**Simplest approach:** Use production key for both DEBUG and RELEASE.

**Your choice:**
- ✅ **Skip Test Store** → Simpler, one environment
- ✅ **Keep Test Store** → Separate test data, more setup

**Both work fine!** Choose based on your preference.

---

*Most apps skip Test Store and just use production key. It's simpler and works great!*
