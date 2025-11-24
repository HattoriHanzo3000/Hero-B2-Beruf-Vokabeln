# URLs Required for App Store Connect Submission

## Required URLs

### 1. Support URL (REQUIRED)
**Purpose:** Provide users with a way to contact you for support, report bugs, or ask questions.

**Requirements:**
- Must be a valid, publicly accessible URL
- Must be accessible without login
- Should contain contact information or support resources

**Options:**

**Option A - If you have a website:**
```
https://www.gizatech.de/support
```
or
```
https://www.gizatech.de/contact
```

**Option B - Simple contact page:**
Create a simple HTML page with:
- App name: Hero - Deutsch B2 Beruf
- Support email: info@gizatech.de
- Brief description of how to get help

**Option C - Email link (if no website):**
You can use a mailto link, but Apple prefers a web page. If you must:
```
mailto:info@gizatech.de?subject=Hero%20-%20Deutsch%20B2%20Beruf%20Support
```

**Recommended Content for Support Page:**
- App name and version
- Contact email: info@gizatech.de
- FAQ section (common questions)
- How to report bugs
- Response time expectations

---

### 2. Marketing URL (OPTIONAL but Recommended)
**Purpose:** Promote your app, showcase features, provide additional information.

**Requirements:**
- Optional field, but recommended for better visibility
- Can be same as Support URL if you don't have a separate marketing site

**Options:**

**Option A - Dedicated landing page:**
```
https://www.gizatech.de/hero-deutsch-b2-beruf
```

**Option B - App section on website:**
```
https://www.gizatech.de/apps
```

**Option C - Same as Support URL:**
If you don't have a separate marketing page, you can use the same URL as Support URL.

**Recommended Content for Marketing Page:**
- App screenshots
- Feature highlights
- Download link to App Store
- Testimonials (if available)
- Video demo (if available)

---

### 3. Privacy Policy URL (REQUIRED)
**Purpose:** Explain what user data your app collects and how it's used.

**Requirements:**
- REQUIRED for App Store submission
- Must be publicly accessible
- Must be accessible without login
- Should be comprehensive and clear

**Options:**

**Option A - Dedicated privacy policy page:**
```
https://www.gizatech.de/privacy-policy
```

**Option B - General privacy policy:**
```
https://www.gizatech.de/privacy
```

**Required Content for Privacy Policy:**
- What data is collected (if any)
- How data is used
- Data storage and security
- Third-party services (if any)
- User rights
- Contact information for privacy concerns

**Note:** Even if your app doesn't collect user data, you still need a privacy policy. It can simply state: "Hero - Deutsch B2 Beruf does not collect, store, or transmit any personal user data. All vocabulary data is stored locally on the device."

---

## Quick Setup Guide

### If You Have a Website (gizatech.de):

1. **Support URL:**
   ```
   https://www.gizatech.de/support
   ```
   Create a page with:
   - Contact: info@gizatech.de
   - FAQ
   - Bug reporting instructions

2. **Marketing URL:**
   ```
   https://www.gizatech.de/hero-deutsch-b2-beruf
   ```
   Create a landing page with app features and screenshots

3. **Privacy Policy URL:**
   ```
   https://www.gizatech.de/privacy-policy
   ```
   Create a privacy policy page

### If You Don't Have a Website Yet:

**Option 1 - Create Simple Pages (Recommended):**
- Use GitHub Pages (free)
- Use Netlify (free)
- Use any free hosting service

**Option 2 - Use Existing Services:**
- Create a simple contact form using Google Forms or Typeform
- Host privacy policy on GitHub Pages

**Option 3 - Minimal Setup:**
- Support URL: Create a simple HTML page with email contact
- Marketing URL: Use same as Support URL or leave blank
- Privacy Policy: Create a simple page stating no data collection

---

## Template Privacy Policy (No Data Collection)

If your app doesn't collect user data, you can use this template:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Privacy Policy - Hero - Deutsch B2 Beruf</title>
</head>
<body>
    <h1>Privacy Policy for Hero - Deutsch B2 Beruf</h1>
    <p><strong>Last Updated:</strong> [Date]</p>
    
    <h2>Data Collection</h2>
    <p>Hero - Deutsch B2 Beruf does not collect, store, or transmit any personal user data. All vocabulary data and user progress are stored locally on your device.</p>
    
    <h2>Third-Party Services</h2>
    <p>This app does not use any third-party analytics or advertising services.</p>
    
    <h2>Contact</h2>
    <p>If you have any questions about this privacy policy, please contact us at: info@gizatech.de</p>
</body>
</html>
```

---

## Current App Information

**Developer:** Gizatech
**Email:** info@gizatech.de
**Bundle ID:** com.gizatech.B2-Beruf
**App Name:** Hero - Deutsch B2 Beruf

---

## Next Steps

1. **Decide on URLs:**
   - Do you have a website? → Use your domain
   - No website? → Create simple pages on GitHub Pages or similar

2. **Create the pages:**
   - Support page (with contact info)
   - Privacy policy page (required)
   - Marketing page (optional but recommended)

3. **Add URLs to App Store Connect:**
   - Go to App Store Connect
   - Navigate to your app
   - Add URLs in App Information section

4. **Test URLs:**
   - Make sure all URLs are accessible
   - Test from different devices/browsers
   - Ensure no login required

