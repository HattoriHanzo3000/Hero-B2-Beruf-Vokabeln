# RevenueCat + Superwall Integration Checklist

This document tracks the remaining steps to complete the RevenueCat + Superwall integration with new pricing.

## ✅ Completed Steps

### Code Integration
- [x] RevenueCat SDK installed and integrated
- [x] Superwall SDK installed and integrated
- [x] RevenueCatService implemented with full functionality
- [x] SuperwallService implemented with RevenueCat integration
- [x] RevenueCatPurchaseController created (connects Superwall to RevenueCat)
- [x] Both services initialized in AppDelegate
- [x] PaywallView updated to use RevenueCat
- [x] Secure API key configuration (AppConfig.swift) created
- [x] Services updated to use AppConfig

---

## ⏳ Remaining Steps

### 1. RevenueCat Dashboard Setup

#### 1.1 Products and Entitlements Configuration
- [ ] **Create Entitlement**
  - Go to: https://app.revenuecat.com → Your Project → Entitlements
  - Create entitlement: `premium` (or update existing)
  - Description: "Premium subscription access"
  
- [ ] **Add Products**
  - Go to: https://app.revenuecat.com → Your Project → Products
  - Add products matching your App Store Connect products:
    - `hero.premium.monthly`
    - `hero.premium.yearly`
    - `hero.premium.lifetime`
  - Link each product to the `premium` entitlement
  
- [ ] **Configure Offerings**
  - Go to: https://app.revenuecat.com → Your Project → Offerings
  - Create or update default offering
  - Add packages for each product:
    - Monthly package → `hero.premium.monthly`
    - Yearly package → `hero.premium.yearly`
    - Lifetime package → `hero.premium.lifetime`
  - Set default package (usually monthly or yearly)

#### 1.2 Promotional Pricing Configuration
- [ ] **Set Up Promotional Offers** (if applicable)
  - Go to: Products → Select product → Promotional Offers
  - Configure introductory offers (free trials, discounted first period)
  - Configure promotional offers (discount codes, special pricing)
  - Set eligibility rules (new users only, etc.)

#### 1.3 API Key Verification
- [ ] **Verify API Key**
  - Current key in AppConfig: `appl_rcEmwNiUYUgSBkoXePHgjfKFjcI`
  - Go to: https://app.revenuecat.com → Your Project → API Keys
  - Verify this matches your Public API Key
  - For production, ensure you're using the production key (not test key)
  - **Optional:** Move API key to Info.plist for better security:
    ```xml
    <key>RevenueCatAPIKey</key>
    <string>appl_rcEmwNiUYUgSBkoXePHgjfKFjcI</string>
    ```

---

### 2. Superwall Dashboard Setup

#### 2.1 Connect Superwall to RevenueCat
- [ ] **Configure RevenueCat Integration**
  - Go to: https://superwall.com/dashboard → Settings → Integrations
  - Find "RevenueCat" integration
  - Add your RevenueCat Public API Key: `appl_rcEmwNiUYUgSBkoXePHgjfKFjcI`
  - Enable event forwarding (purchases, renewals, cancellations)
  - This allows Superwall to track subscription events from RevenueCat

#### 2.2 Set Up Paywall Triggers
- [ ] **Create Paywall Campaigns**
  - Go to: https://superwall.com/dashboard → Campaigns
  - Create campaigns for different paywall triggers:
    - **Onboarding Paywall** (placement: `onboarding`)
    - **Feature Lock Paywall** (placement: `feature_lock`)
    - **Upgrade Prompt** (placement: `upgrade_prompt`)
  
- [ ] **Configure Paywall Designs**
  - Design paywalls in Superwall dashboard
  - Link to RevenueCat products (they should sync automatically)
  - Test different paywall variants
  
- [ ] **Set Up Placement Triggers**
  - Configure when paywalls should appear:
    - After X app opens
    - When accessing premium features
    - On specific user actions
  - Set frequency capping (don't show too often)

#### 2.3 API Key Verification
- [ ] **Verify API Key**
  - Current key in AppConfig: `pk_FkOPYHsQH06fg63Xr0lTU`
  - Go to: https://superwall.com/dashboard → Settings → API Keys
  - Verify this matches your API Key
  - For production, ensure you're using the production key
  - **Optional:** Move API key to Info.plist for better security:
    ```xml
    <key>SuperwallAPIKey</key>
    <string>pk_FkOPYHsQH06fg63Xr0lTU</string>
    ```

---

### 3. Secure Configuration (Optional but Recommended)

#### 3.1 Move API Keys to Info.plist
- [ ] **Add API Keys to Info.plist**
  - Open: `B2-Berufssprachkurs-Info.plist`
  - Add these keys:
    ```xml
    <key>RevenueCatAPIKey</key>
    <string>YOUR_REVENUECAT_API_KEY</string>
    <key>SuperwallAPIKey</key>
    <string>YOUR_SUPERWALL_API_KEY</string>
    ```
  - AppConfig.swift will automatically read from Info.plist
  - **Important:** Add `B2-Berufssprachkurs-Info.plist` to `.gitignore` if it contains production keys

#### 3.2 Environment Variables (For CI/CD)
- [ ] **Set Up CI/CD Secrets** (if using CI/CD)
  - Add environment variables:
    - `REVENUECAT_API_KEY`
    - `SUPERWALL_API_KEY`
  - AppConfig.swift will automatically read from environment variables

---

### 4. Testing

#### 4.1 Subscription Purchase Testing
- [ ] **Test Monthly Subscription**
  - Use sandbox test account
  - Trigger paywall
  - Purchase monthly subscription
  - Verify:
    - Purchase completes successfully
    - Premium access is granted immediately
    - RevenueCat dashboard shows purchase
    - Superwall dashboard shows event
  
- [ ] **Test Yearly Subscription**
  - Purchase yearly subscription
  - Verify premium access
  - Check both dashboards

- [ ] **Test Lifetime Purchase**
  - Purchase lifetime subscription
  - Verify premium access
  - Check both dashboards

#### 4.2 Free Trial Testing
- [ ] **Test Free Trial** (if configured)
  - Start free trial
  - Verify:
    - Premium access granted during trial
    - Trial period shows correctly
    - Auto-renewal settings correct
    - Trial expiration handling

#### 4.3 Promotional Pricing Testing
- [ ] **Test Promotional Offers** (if configured)
  - Test introductory offers
  - Test discount codes
  - Verify pricing displays correctly
  - Check eligibility rules work

#### 4.4 Restore Purchases Testing
- [ ] **Test Restore Purchases**
  - On a device with existing subscription
  - Tap "Restore Purchases"
  - Verify:
    - Subscription is restored
    - Premium access granted
    - RevenueCat dashboard shows restore event
    - Superwall dashboard shows event

#### 4.5 Dashboard Verification
- [ ] **Verify RevenueCat Dashboard**
  - Check Events tab for purchase events
  - Verify customer info is correct
  - Check entitlements are active
  - Verify products are linked correctly

- [ ] **Verify Superwall Dashboard**
  - Check Events tab for paywall events
  - Verify purchase events are forwarded from RevenueCat
  - Check paywall presentation metrics
  - Verify conversion rates

#### 4.6 Edge Cases Testing
- [ ] **Test Cancellation Flow**
  - Cancel subscription
  - Verify premium access revoked at period end
  - Test restore after cancellation

- [ ] **Test Family Sharing** (if enabled)
  - Verify family sharing works
  - Test restore on family member device

- [ ] **Test Network Issues**
  - Test with poor connectivity
  - Verify error handling
  - Test retry mechanisms

---

## 📋 Quick Verification Checklist

Before going to production, verify:

- [ ] All products configured in RevenueCat dashboard
- [ ] Entitlements linked to products
- [ ] Offerings configured with packages
- [ ] Superwall connected to RevenueCat
- [ ] Paywall triggers configured in Superwall
- [ ] API keys verified and secure
- [ ] All subscription types tested (monthly, yearly, lifetime)
- [ ] Free trial tested (if applicable)
- [ ] Promotional pricing tested (if applicable)
- [ ] Restore purchases tested
- [ ] Both dashboards showing events correctly
- [ ] Premium access working correctly
- [ ] Error handling tested

---

## 🔧 Troubleshooting

### API Keys Not Working
- Verify keys are correct in AppConfig or Info.plist
- Check console for initialization errors
- Ensure keys match dashboard (test vs production)

### Products Not Loading
- Verify products exist in RevenueCat dashboard
- Check product IDs match exactly (case-sensitive)
- Ensure offerings are configured
- Check network connectivity

### Purchases Not Completing
- Verify sandbox test account is signed in
- Check App Store Connect products are approved
- Verify RevenueCat products are linked correctly
- Check console for error messages

### Superwall Not Showing Paywalls
- Verify Superwall API key is correct
- Check paywall campaigns are active
- Verify placement identifiers match
- Check Superwall dashboard for errors

### Events Not Appearing in Dashboards
- Verify integration between RevenueCat and Superwall
- Check API keys are correct
- Ensure events are being sent (check console logs)
- Wait a few minutes for dashboard sync

---

## 📝 Notes

- **Current API Keys:**
  - RevenueCat: `appl_rcEmwNiUYUgSBkoXePHgjfKFjcI`
  - Superwall: `pk_FkOPYHsQH06fg63Xr0lTU`

- **Product IDs:**
  - Monthly: `hero.premium.monthly`
  - Yearly: `hero.premium.yearly`
  - Lifetime: `hero.premium.lifetime`

- **Entitlement ID:**
  - Premium: `premium`

- **AppConfig.swift** provides secure API key management with fallback options

---

## ✅ Completion Status

**Code Integration:** ✅ Complete  
**Dashboard Setup:** ⏳ In Progress  
**Testing:** ⏳ Pending  
**Production Ready:** ⏳ Pending

---

*Last Updated: [Current Date]*  
*Next Review: After dashboard setup completion*
