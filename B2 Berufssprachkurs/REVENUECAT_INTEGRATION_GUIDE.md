# RevenueCat Integration Guide

## Overview

This guide covers the complete RevenueCat SDK integration for Hero Deutsch B2 Beruf app, including subscription management, paywalls, and customer center.

## ✅ What's Already Set Up

1. **SDK Installation**: RevenueCat and RevenueCatUI are installed via Swift Package Manager
2. **API Key Configuration**: Test API key is configured in `RevenueCatService.swift`
3. **Service Initialization**: RevenueCat initializes automatically on app launch
4. **Entitlement Checking**: Premium entitlement ("premium") is configured
5. **Product IDs**: All product variants are configured

## 📦 Product Configuration

### Product Identifiers

The following product IDs are configured:
- `hero.premium.monthly` - Premium Monthly
- `hero.premium.yearly` - Premium Yearly  
- `hero.premium.lifetime` - Premium Lifetime
- `monthly` - Monthly (alternative)
- `yearly` - Yearly (alternative)
- `lifetime` - Lifetime (alternative)

### RevenueCat Dashboard Setup

1. **Create Entitlement**: 
   - Go to RevenueCat Dashboard → Entitlements
   - Create entitlement with identifier: `premium`
   - Attach your products to this entitlement

2. **Create Offering**:
   - Go to RevenueCat Dashboard → Offerings
   - Create a default offering
   - Add packages for your products
   - Configure package identifiers (e.g., "monthly", "yearly", "lifetime")

3. **Link App Store Products**:
   - Go to RevenueCat Dashboard → Products
   - Add your App Store Connect product IDs
   - Link them to the "premium" entitlement

## 🚀 Usage Examples

### 1. Check Premium Status

```swift
import RevenueCat

// Simple check
if RevenueCatService.shared.isPremiumActive {
    // User has premium access
}

// Async check with latest info
let hasPremium = await RevenueCatService.shared.checkEntitlement("premium")
```

### 2. Present Paywall

```swift
import SwiftUI

struct ContentView: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button("Upgrade to Premium") {
            showPaywall = true
        }
        .sheet(isPresented: $showPaywall) {
            RevenueCatPaywallView()
        }
    }
}
```

### 3. Purchase a Product

```swift
// Purchase by package identifier
if let package = RevenueCatService.shared.getPackage(identifier: "monthly") {
    do {
        let (customerInfo, _) = try await RevenueCatService.shared.purchase(package: package)
        // Purchase successful
    } catch {
        // Handle error
    }
}

// Or purchase by product identifier
do {
    let customerInfo = try await RevenueCatService.shared.purchase(productIdentifier: "hero.premium.monthly")
    // Purchase successful
} catch {
    // Handle error
}
```

### 4. Restore Purchases

```swift
do {
    try await RevenueCatService.shared.restorePurchases()
    // Purchases restored
} catch {
    // Handle error
}
```

### 5. Present Customer Center

```swift
import SwiftUI

struct SettingsView: View {
    @State private var showCustomerCenter = false
    
    var body: some View {
        Button("Manage Subscription") {
            showCustomerCenter = true
        }
        .sheet(isPresented: $showCustomerCenter) {
            CustomerCenterView()
        }
    }
}
```

### 6. Get Offerings and Packages

```swift
// Load offerings
await RevenueCatService.shared.loadOfferings()

// Get current offering
if let offering = RevenueCatService.shared.currentOffering {
    // Use offering
}

// Get available packages
let packages = RevenueCatService.shared.getAvailablePackages()
for package in packages {
    print("Package: \(package.identifier)")
    print("Product: \(package.storeProduct.localizedTitle)")
    print("Price: \(package.storeProduct.localizedPriceString)")
}
```

### 7. Monitor Subscription Status

```swift
import Combine

class MyViewModel: ObservableObject {
    @Published var isPremium = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        RevenueCatService.shared.$isPremiumActive
            .assign(to: &$isPremium)
    }
}
```

## 🔧 Advanced Usage

### Custom Paywall Options

```swift
let paywallOptions = PaywallOptions()
    .paywallFooter { info in
        // Custom footer view
        VStack {
            Text("Custom footer content")
        }
    }

PaywallView(offering: offering, options: paywallOptions)
```

### User Identification

```swift
// Identify user after login
try await RevenueCatService.shared.identifyUser(userID: "user123")

// Log out user
try await RevenueCatService.shared.logOut()
```

### Subscription Status Details

```swift
let service = RevenueCatService.shared

// Check subscription status
switch service.subscriptionStatus {
case .active:
    print("Subscription is active")
case .expired:
    print("Subscription has expired")
case .gracePeriod:
    print("Subscription is in grace period")
case .none:
    print("No subscription")
}

// Check expiration date
if let expirationDate = service.premiumExpirationDate {
    print("Expires on: \(expirationDate)")
}

// Check if in grace period
if service.isInGracePeriod {
    print("Subscription is in grace period")
}
```

## 🔄 Integration with Existing SubscriptionManager

The `RevenueCatIntegrationHelper` automatically syncs between RevenueCat and your existing `SubscriptionManager`:

```swift
// Manual sync
await RevenueCatIntegrationHelper.shared.syncBothServices()

// Get unified premium status
let isPremium = RevenueCatIntegrationHelper.shared.isPremiumActive
```

## 🎨 Customization

### Custom Paywall Appearance

You can customize the RevenueCat paywall by modifying `RevenueCatPaywallView.swift`:

```swift
private var paywallOptions: PaywallOptions {
    PaywallOptions()
        .paywallFooter { info in
            // Add custom footer
            VStack {
                Text("Custom content")
            }
        }
}
```

### Error Handling

All RevenueCat methods throw `RevenueCatError`:

```swift
do {
    try await RevenueCatService.shared.purchase(productIdentifier: "monthly")
} catch RevenueCatError.userCancelled {
    // User cancelled
} catch RevenueCatError.purchaseFailed(let message) {
    // Purchase failed
    print("Error: \(message)")
} catch {
    // Other errors
    print("Unexpected error: \(error)")
}
```

## 📝 Best Practices

1. **Always Check Entitlements**: Use `isPremiumActive` or `checkEntitlement()` rather than checking products directly
2. **Handle Errors Gracefully**: Always wrap purchase operations in do-catch blocks
3. **Sync Customer Info**: Call `syncCustomerInfo()` after important operations
4. **Monitor Status**: Use Combine publishers to react to subscription status changes
5. **Test Thoroughly**: Test with sandbox accounts and test products

## 🧪 Testing

### Sandbox Testing

1. Use sandbox test accounts in App Store Connect
2. Test purchases with sandbox products
3. Verify entitlements are granted correctly
4. Test restore purchases functionality

### Debug Helpers

```swift
#if DEBUG
// Print customer info
RevenueCatService.shared.printCustomerInfo()

// Check if can make purchases
let canPurchase = RevenueCatService.shared.canMakePurchases
print("Can make purchases: \(canPurchase)")
#endif
```

## 🔐 Production Setup

Before releasing to production:

1. **Update API Key**: Replace test API key with production key in `RevenueCatService.swift`
2. **Verify Products**: Ensure all products are configured in RevenueCat dashboard
3. **Test Offerings**: Verify offerings are set up correctly
4. **Enable Entitlements**: Ensure entitlements are properly configured
5. **Test Restore**: Verify restore purchases works correctly

## 📚 Additional Resources

- [RevenueCat Documentation](https://www.revenuecat.com/docs)
- [RevenueCat iOS SDK Reference](https://www.revenuecat.com/docs/ios)
- [RevenueCat Paywalls Guide](https://www.revenuecat.com/docs/tools/paywalls)
- [Customer Center Guide](https://www.revenuecat.com/docs/tools/customer-center)

## 🆘 Troubleshooting

### No Offerings Available

- Check RevenueCat dashboard for offering configuration
- Verify products are linked to offerings
- Check internet connection
- Call `loadOfferings()` manually

### Purchases Not Working

- Verify API key is correct
- Check product IDs match App Store Connect
- Ensure products are approved in App Store Connect
- Test with sandbox account

### Entitlements Not Activating

- Verify entitlement identifier matches ("premium")
- Check products are linked to entitlement in dashboard
- Ensure purchases complete successfully
- Call `syncCustomerInfo()` after purchase
