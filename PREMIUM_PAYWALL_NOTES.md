# Premium View and Paywall Implementation Notes

## Overview
This document describes the premium subscription flow and paywall implementation in the Hero - Deutsch B2 Beruf app.

## Components

### 1. PremiumView (`08 - Views/04 - Settings/PremiumView.swift`)
- **Location**: Premium Tab in MainTabView
- **Purpose**: Displays premium features comparison table
- **Key Features**:
  - Crown icon and title
  - Comparison table showing Free vs Premium features
  - "Unlock Premium" button at the bottom (fixed above tab bar)
  - Opens PaywallView when button is tapped

### 2. PaywallView (`08 - Views/04 - Settings/PaywallView.swift`)
- **Presentation**: Bottom sheet (slides up from bottom)
- **Purpose**: Subscription purchase interface
- **Key Features**:
  - Crown icon at top
  - Title: "Unlock the full Hero experience"
  - Subtitle: Premium benefits description
  - Monthly subscription option (1,99€ per month) with checkmark selection
  - Terms and conditions text
  - "Continue" button at bottom
  - System drag indicator for dismissal

## User Flow

1. User navigates to **Premium Tab**
2. Sees PremiumView with comparison table
3. Taps **"Unlock Premium"** button
4. PaywallView appears as bottom sheet
5. User sees subscription details and taps **"Continue"**
6. ⚠️ **TODO**: Implement StoreKit purchase flow
7. iOS native purchase dialog appears
8. User completes purchase
9. Subscription activated, premium features unlocked

## Subscription Details

- **Product ID**: `monthly_1.99_3d_trial`
- **Price**: 1,99€ per month
- **Free Trial**: 3 days
- **Reference Name**: Pro Access | Monthly

## Localization

All strings are localized in:
- `09 - Resources/03 - Localisations/en.lproj/Localizable.strings`
- `09 - Resources/03 - Localisations/de.lproj/Localizable.strings`

### Key Localization Keys:
- `unlock_premium` - "Unlock Premium" / "Premium freischalten"
- `unlock_full_hero_experience` - Title in paywall
- `pro_benefits_description` - Subtitle description
- `monthly_subscription` - "Monthly" / "Monatlich"
- `per_month` - "per month" / "pro Monat"
- `continue_button` - "Continue" / "Weiter"
- `subscription_terms` - Full terms and conditions text

## Next Steps (TODO)

### Required Implementation:
1. **Create SubscriptionManager service**
   - Load products from App Store Connect
   - Handle purchase transactions
   - Check subscription status
   - Listen for subscription updates

2. **Integrate StoreKit 2**
   - Import StoreKit framework
   - Implement purchase flow in PaywallView
   - Handle transaction verification
   - Update premium status throughout app

3. **Premium Feature Gating**
   - Check subscription status before showing premium features
   - Hide ads when premium is active
   - Unlock premium study modes
   - Enable detailed progress tracking

### App Store Connect Setup:
- ✅ Subscription created: `monthly_1.99_3d_trial`
- ✅ Localization added (English & German)
- ⚠️ **Pending**: Link subscription to app version for first submission
- ⚠️ **Pending**: Submit app version with subscription for review

## Technical Notes

- PaywallView uses `.presentationDetents([.large])` for bottom sheet presentation
- PremiumView button is fixed above tab bar for easy access
- All premium-related UI follows app's design system (AppGreen, AppBlue colors)
- Haptic feedback integrated for button interactions

## Files Modified

- `08 - Views/04 - Settings/PremiumView.swift` - Premium tab view
- `08 - Views/04 - Settings/PaywallView.swift` - Subscription paywall
- `Localizable.swift` - Added premium/paywall localization keys
- `09 - Resources/03 - Localisations/en.lproj/Localizable.strings` - English strings
- `09 - Resources/03 - Localisations/de.lproj/Localizable.strings` - German strings



