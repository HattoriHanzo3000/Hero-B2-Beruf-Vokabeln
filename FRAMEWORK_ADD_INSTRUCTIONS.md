# How to Add AppTrackingTransparency Framework

## Quick Steps

1. **Open your project in Xcode**

2. **Select the Project**
   - Click on "B2 Berufssprachkurs" (blue icon) in the Project Navigator (left sidebar)

3. **Select the Target**
   - Under "TARGETS", select "B2 Berufssprachkurs"

4. **Go to General Tab**
   - Click on the "General" tab at the top

5. **Find Frameworks Section**
   - Scroll down to "Frameworks, Libraries, and Embedded Content"
   - You should see "GoogleMobileAds" listed there

6. **Add AppTrackingTransparency**
   - Click the **+** button (bottom left of the frameworks list)
   - In the search box, type: `AppTrackingTransparency`
   - Select: `AppTrackingTransparency.framework`
   - Click **Add**

7. **Set Embedding**
   - Find `AppTrackingTransparency.framework` in the list
   - Change the dropdown from "Embed & Sign" to **"Do Not Embed"**
   - (This is a system framework, so it doesn't need to be embedded)

## Visual Guide

```
Xcode Project Navigator
├── B2 Berufssprachkurs (Project)
│   ├── TARGETS
│   │   └── B2 Berufssprachkurs ← Select this
│   │       ├── General tab ← Go here
│   │       │   └── Frameworks, Libraries, and Embedded Content
│   │       │       ├── GoogleMobileAds (already there)
│   │       │       └── + button ← Click to add
│   │       │           └── Search: AppTrackingTransparency
│   │       │               └── Select: AppTrackingTransparency.framework
│   │       │                   └── Set to: "Do Not Embed"
```

## Verification

After adding, you should see:
- `AppTrackingTransparency.framework` in the frameworks list
- Set to "Do Not Embed"
- Project builds without errors
- `TrackingManager.swift` compiles successfully

## Why This Matters

- **Clarity:** Explicitly shows the framework is used
- **Best Practice:** Recommended by Apple for system frameworks
- **Avoid Issues:** Prevents potential linking problems
- **App Store:** Some reviewers may check for explicit framework linking

## Alternative: Test First

If you want to test if it works without adding:
1. Try building the project (Cmd+B)
2. If it builds successfully → Framework may be auto-linked
3. If you see errors → Add the framework explicitly

**Recommendation:** Add it explicitly to be safe! ✅

