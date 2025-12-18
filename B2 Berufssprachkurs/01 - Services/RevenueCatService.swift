//
//  RevenueCatService.swift
//  B2 Berufssprachkurs
//
//  Created for RevenueCat + Superwall Integration
//

import Foundation
import Combine
import RevenueCat

@MainActor
final class RevenueCatService: NSObject, ObservableObject {
    static let shared = RevenueCatService()
    
    // MARK: - Published Properties
    
    @Published var isInitialized = false
    @Published var customerInfo: CustomerInfo?
    @Published var isPremiumActive = false
    @Published var activeEntitlements: Set<String> = []
    @Published var errorMessage: String?
    @Published var offerings: Offerings?
    @Published var currentOffering: Offering?
    @Published var isLoadingOfferings = false
    
    // MARK: - Configuration
    
    /// RevenueCat API Key - Retrieved from AppConfig for secure management
    /// Get it from: https://app.revenuecat.com → Your Project → API Keys
    private var apiKey: String {
        AppConfig.revenueCatAPIKey
    }
    
    /// App User ID - RevenueCat will use anonymous ID if not provided
    /// Set this to a specific user ID if you have user authentication
    private var appUserID: String? {
        // You can customize this to use a specific user ID
        // For now, we'll let RevenueCat generate an anonymous ID
        return nil
    }
    
    // MARK: - Product Identifiers
    
    /// Product IDs that match your App Store Connect products
    /// These should match the product IDs in SubscriptionManager
    private let productIDs = [
        "hero.premium.monthly",
        "hero.premium.yearly",
        "hero.premium.yearly.promo",
        "hero.premium.lifetime"
    ]
    
    /// Entitlement identifier from RevenueCat dashboard
    /// This is the identifier you configure in RevenueCat for premium access
    private let premiumEntitlementID = "premium"
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        // Initialize RevenueCat SDK
        configureRevenueCat()
    }
    
    // MARK: - Configuration
    
    private func configureRevenueCat() {
        guard !apiKey.contains("YOUR_") else {
            print("⚠️ RevenueCatService: API key not configured. Please add your RevenueCat API key.")
            errorMessage = "RevenueCat API key not configured"
            return
        }
        
        // Configure RevenueCat SDK
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: apiKey)
                .with(storeKitVersion: .storeKit2)
                .with(appUserID: appUserID)
                .build()
        )
        
        // Set delegate to receive updates
        Purchases.shared.delegate = self
        
        isInitialized = true
        print("✅ RevenueCatService: SDK initialized successfully")
        
        // Load customer info and offerings immediately
        Task {
            await syncCustomerInfo()
            await loadOfferings()
        }
    }
    
    // MARK: - Customer Info Sync
    
    /// Syncs the latest customer information from RevenueCat
    func syncCustomerInfo() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await updateCustomerInfo(customerInfo)
        } catch {
            print("❌ RevenueCatService: Error syncing customer info - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    private func updateCustomerInfo(_ customerInfo: CustomerInfo) async {
        self.customerInfo = customerInfo
        
        // Check premium entitlement
        let hasPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
        
        // Get all active entitlements
        let activeEntitlements = Set(customerInfo.entitlements.active.keys)
        
        await MainActor.run {
            self.isPremiumActive = hasPremium
            self.activeEntitlements = activeEntitlements
        }
        
        print("✅ RevenueCatService: Customer info updated - Premium: \(hasPremium)")
    }
    
    // MARK: - User Identification
    
    /// Identify the current user with a custom user ID
    /// Call this after user login/registration
    func identifyUser(userID: String) async throws {
        let (customerInfo, created) = try await Purchases.shared.logIn(userID)
        await updateCustomerInfo(customerInfo)
        if created {
            print("✅ RevenueCatService: New user created - \(userID)")
        } else {
            print("✅ RevenueCatService: User identified - \(userID)")
        }
    }
    
    /// Log out the current user and switch to anonymous
    func logOut() async throws {
        let customerInfo = try await Purchases.shared.logOut()
        await updateCustomerInfo(customerInfo)
        print("✅ RevenueCatService: User logged out")
    }
    
    // MARK: - Offerings & Products
    
    /// Fetches available offerings from RevenueCat
    func getOfferings() async throws -> Offerings {
        let offerings = try await Purchases.shared.offerings()
        await MainActor.run {
            self.offerings = offerings
            self.currentOffering = offerings.current
        }
        return offerings
    }
    
    /// Gets the current offering (typically the default offering)
    func getCurrentOffering() async throws -> Offering? {
        if let currentOffering = currentOffering {
            return currentOffering
        }
        
        let offerings = try await getOfferings()
        return offerings.current
    }
    
    /// Loads offerings and updates published properties
    func loadOfferings() async {
        isLoadingOfferings = true
        errorMessage = nil
        
        do {
            let offerings = try await getOfferings()
            await MainActor.run {
                self.offerings = offerings
                self.currentOffering = offerings.current
                self.isLoadingOfferings = false
            }
            print("✅ RevenueCatService: Offerings loaded successfully")
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load offerings: \(error.localizedDescription)"
                self.isLoadingOfferings = false
            }
            print("❌ RevenueCatService: Error loading offerings - \(error.localizedDescription)")
        }
    }
    
    /// Gets a package by identifier from the current offering
    func getPackage(identifier: String) -> Package? {
        return currentOffering?.package(identifier: identifier)
    }
    
    /// Gets all available packages from the current offering
    func getAvailablePackages() -> [Package] {
        return currentOffering?.availablePackages ?? []
    }
    
    // MARK: - Purchase Management
    
    /// Purchases a package from RevenueCat
    func purchase(package: Package) async throws -> (CustomerInfo, Bool) {
        let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
        
        await updateCustomerInfo(customerInfo)
        
        if userCancelled {
            throw RevenueCatError.userCancelled
        }
        
        print("✅ RevenueCatService: Purchase successful - \(package.storeProduct.productIdentifier)")
        return (customerInfo, userCancelled)
    }
    
    /// Purchases a product by identifier (finds package automatically)
    func purchase(productIdentifier: String) async throws -> CustomerInfo {
        guard let offering = try await getCurrentOffering() else {
            throw RevenueCatError.purchaseFailed("No offering available")
        }
        
        // Try to find package by identifier first
        if let package = offering.package(identifier: productIdentifier) {
            let (customerInfo, userCancelled) = try await purchase(package: package)
            if userCancelled {
                throw RevenueCatError.userCancelled
            }
            return customerInfo
        }
        
        // If not found by identifier, search in available packages
        if let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == productIdentifier }) {
            let (customerInfo, userCancelled) = try await purchase(package: package)
            if userCancelled {
                throw RevenueCatError.userCancelled
            }
            return customerInfo
        }
        
        throw RevenueCatError.packageNotFound(productIdentifier)
    }
    
    /// Restores previous purchases
    func restorePurchases() async throws {
        let customerInfo = try await Purchases.shared.restorePurchases()
        await updateCustomerInfo(customerInfo)
        print("✅ RevenueCatService: Purchases restored")
    }
    
    /// Checks if purchases can be made (for family sharing, etc.)
    var canMakePurchases: Bool {
        return Purchases.canMakePayments()
    }
    
    // MARK: - Subscription Status
    
    /// Checks if user has active premium subscription
    var hasActivePremium: Bool {
        return isPremiumActive
    }
    
    /// Convenience method to check if a specific entitlement is active
    /// Usage: `let hasPremium = await RevenueCatService.shared.checkEntitlement("premium")`
    func checkEntitlement(_ entitlementID: String = "premium") async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            return customerInfo.entitlements.all[entitlementID]?.isActive == true
        } catch {
            print("❌ RevenueCatService: Error checking entitlement - \(error.localizedDescription)")
            return false
        }
    }
    
    /// Gets the active product identifier if available
    var activeProductID: String? {
        guard let customerInfo = customerInfo,
              let entitlement = customerInfo.entitlements[premiumEntitlementID],
              entitlement.isActive else {
            return nil
        }
        
        // Get the product identifier from the active entitlement
        return entitlement.productIdentifier
    }
    
    /// Gets the expiration date of the premium subscription
    var premiumExpirationDate: Date? {
        guard let customerInfo = customerInfo,
              let entitlement = customerInfo.entitlements[premiumEntitlementID],
              entitlement.isActive else {
            return nil
        }
        
        return entitlement.expirationDate
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    /// Debug method to print current customer info
    func printCustomerInfo() {
        guard let customerInfo = customerInfo else {
            print("RevenueCatService: No customer info available")
            return
        }
        
        print("=== RevenueCat Customer Info ===")
        print("User ID: \(customerInfo.originalAppUserId)")
        print("Active Entitlements: \(customerInfo.entitlements.active.keys.joined(separator: ", "))")
        print("Premium Active: \(isPremiumActive)")
        if let expirationDate = premiumExpirationDate {
            print("Premium Expires: \(expirationDate)")
        }
        print("================================")
    }
    #endif
    
    // MARK: - Subscription Management
    
    /// Gets subscription status information
    /// Available for advanced subscription status checking
    var subscriptionStatus: SubscriptionStatus {
        guard let customerInfo = customerInfo,
              let entitlement = customerInfo.entitlements[premiumEntitlementID] else {
            return .none
        }
        
        if entitlement.isActive {
            if entitlement.willRenew {
                return .active
            } else {
                return .expired
            }
        } else {
            return .expired
        }
    }
    
    /// Checks if subscription is in grace period
    /// Available for grace period detection
    var isInGracePeriod: Bool {
        guard let customerInfo = customerInfo,
              let entitlement = customerInfo.entitlements[premiumEntitlementID] else {
            return false
        }
        // Check if entitlement is active but in grace period
        return entitlement.isActive && !entitlement.willRenew && entitlement.expirationDate != nil
    }
    
    /// Gets the latest transaction date
    /// Available for transaction history
    var latestTransactionDate: Date? {
        return customerInfo?.latestExpirationDate
    }
    
    /// Gets the first seen date for the user
    /// Available for user analytics
    var firstSeenDate: Date? {
        return customerInfo?.firstSeen
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            await updateCustomerInfo(customerInfo)
        }
    }
    
    nonisolated func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase startPurchase: @escaping StartPurchaseBlock) {
        // Handle promoted purchases if needed
        // Start the purchase flow when a promoted product is detected
        startPurchase { [weak self] (transaction, customerInfo, error, userCancelled) in
            // Purchase completed or cancelled
            if let customerInfo = customerInfo {
                Task { @MainActor [weak self] in
                    await self?.updateCustomerInfo(customerInfo)
                }
            }
        }
    }
}

// MARK: - Subscription Status

enum SubscriptionStatus {
    case none
    case active
    case expired
    case gracePeriod
}

// MARK: - RevenueCat Errors

enum RevenueCatError: LocalizedError {
    case notInitialized
    case userCancelled
    case purchaseFailed(String)
    case customerInfoUnavailable
    case offeringUnavailable
    case packageNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "RevenueCat SDK is not initialized"
        case .userCancelled:
            return "Purchase was cancelled by the user"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .customerInfoUnavailable:
            return "Customer information is not available"
        case .offeringUnavailable:
            return "No offering is currently available"
        case .packageNotFound(let identifier):
            return "Package '\(identifier)' not found in current offering"
        }
    }
}
