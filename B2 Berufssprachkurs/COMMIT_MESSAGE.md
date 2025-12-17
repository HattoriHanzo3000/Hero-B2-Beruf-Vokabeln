# Commit Message

```
feat: Integrate RevenueCat + Superwall with new pricing and holiday banner

- Add RevenueCat and Superwall SDK integration
  - RevenueCatService: Complete subscription management
  - SuperwallService: Paywall integration with RevenueCat
  - AppConfig: Secure API key management
  - RevenueCatPurchaseController: Connects Superwall to RevenueCat

- Update PaywallView with new pricing
  - New subscription prices (monthly, yearly, lifetime)
  - Holiday seasonal banner integration
  - Enhanced UI with RevenueCat integration

- Update SubscriptionManager
  - Integrate with RevenueCat as primary source
  - Maintain backward compatibility with StoreKit

- Add secure configuration
  - AppConfig.swift for API key management
  - Support for Info.plist and environment variables

- Update AppDelegate
  - Initialize RevenueCat and Superwall on app launch

- Add documentation
  - Integration guides and setup instructions
  - API key management documentation
  - Dashboard setup guides
```
