# How to Add SKAdNetworkItems to Info.plist

## Status

✅ **NSUserTrackingUsageDescription** - Already added to project.pbxproj  
⚠️ **SKAdNetworkItems** - Needs to be added via Xcode (array structure)

## Why SKAdNetworkItems Needs Manual Addition

`SKAdNetworkItems` is a complex array structure that's difficult to add programmatically to `project.pbxproj`. The easiest way is to add it via Xcode's Info tab.

## Step-by-Step Instructions

### Method 1: Via Xcode Info Tab (Recommended)

1. **Open Xcode**
2. **Select your project** in the navigator (blue icon "B2 Berufssprachkurs")
3. **Select the target:** "B2 Berufssprachkurs" (under TARGETS)
4. **Go to Info tab** (next to General, Signing & Capabilities, etc.)
5. **Click the + button** (bottom left of the key-value pairs)
6. **Type:** `SKAdNetworkItems`
7. **Set Type to:** `Array`
8. **Click the + button** next to the array to add items
9. **For each SKAdNetwork identifier:**
   - Click + to add a new item
   - Set Type to: `Dictionary`
   - Click + inside the dictionary
   - Add key: `SKAdNetworkIdentifier` (Type: String)
   - Add value: The identifier (e.g., `cstr6suwn9.skadnetwork`)

### Method 2: Create Info.plist File (Alternative)

If you prefer, you can create an actual `Info.plist` file:

1. **Create new file:** `B2 Berufssprachkurs/Info.plist`
2. **Add to target:** Make sure it's included in the app target
3. **Set in Build Settings:** 
   - Find `INFOPLIST_FILE` setting
   - Set it to: `B2 Berufssprachkurs/Info.plist`
   - Remove or comment out `GENERATE_INFOPLIST_FILE = YES`

## Required SKAdNetwork Identifiers

Here's the complete list you need to add (from Google's documentation):

```
cstr6suwn9.skadnetwork
4fzdc2evr5.skadnetwork
4pfyvq9l8r.skadnetwork
2fnua5tdw4.skadnetwork
ydx93a7ass.skadnetwork
5a6flpkh64.skadnetwork
p78axxw29g.skadnetwork
v72qych5uu.skadnetwork
ludvb6z3bs.skadnetwork
cp8zw746q7.skadnetwork
3sh42y64q3.skadnetwork
c6k4g5qg8m.skadnetwork
s39g8k73mm.skadnetwork
3qy4746246.skadnetwork
f38h382jlk.skadnetwork
hs6bdukanm.skadnetwork
prcb7njmu6.skadnetwork
v4nxqhlyqp.skadnetwork
wzmmz9fp6w.skadnetwork
yclnxrl5pm.skadnetwork
t38b2kh725.skadnetwork
7ug5zh24hu.skadnetwork
gta9lk7p23.skadnetwork
vutu7akeur.skadnetwork
y5ghdn5j9q.skadnetwork
n6fk4nfna4.skadnetwork
v9wttpbfk9.skadnetwork
n38lu8286q.skadnetwork
47vhws6wlr.skadnetwork
kbd757ywx3.skadnetwork
9t245vhmpl.skadnetwork
eh6m2bh4zr.skadnetwork
a2p9lx4jpn.skadnetwork
22mmun2rn5.skadnetwork
4468km3ulz.skadnetwork
2u9pt9hc89.skadnetwork
8s468mfl3y.skadnetwork
klf5c3l5u5.skadnetwork
ppxm28t8ap.skadnetwork
ecpz2srf59.skadnetwork
uw77j35x4d.skadnetwork
pwa83g58rt.skadnetwork
mlmmfzh3r3.skadnetwork
578prtvx9j.skadnetwork
4dzt52r2t5.skadnetwork
e5fvkxwrpn.skadnetwork
8c4e2ghe7u.skadnetwork
zq492l623r.skadnetwork
3qcr597p9d.skadnetwork
```

## Quick Reference: What's Already Done

✅ `GADApplicationIdentifier` - Added to project.pbxproj  
✅ `NSUserTrackingUsageDescription` - Added to project.pbxproj  
⚠️ `SKAdNetworkItems` - **You need to add this via Xcode**

## Verification

After adding SKAdNetworkItems:
1. Build the project (Cmd+B)
2. Check that it builds successfully
3. Verify in the generated Info.plist (in build products) that SKAdNetworkItems appears

## Note

Google periodically updates the list of SKAdNetwork identifiers. Check the latest list at:
https://developers.google.com/admob/ios/ios14#skadnetworkids

---

**Current Status:** NSUserTrackingUsageDescription is done. SKAdNetworkItems needs to be added via Xcode's Info tab.

