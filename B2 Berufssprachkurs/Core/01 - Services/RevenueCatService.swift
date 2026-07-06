//
//  RevenueCatService.swift
//  B2 Berufssprachkurs
//
//  Wraps RevenueCat SDK setup, offerings, and customer info access.
//  Created: 17.12.25.
//

import Combine
import Foundation
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
    private var apiKey: String {
        AppConfig.revenueCatAPIKey
    }

    /// Stable app user id persisted in Keychain so RevenueCat identity
    /// stays consistent across launches/rebuilds on the same device.
    private var appUserID: String? {
        RevenueCatStableUserIDStore.getOrCreate()
    }

    /// Entitlement identifier from RevenueCat dashboard
    private let premiumEntitlementID = "premium"

    // MARK: - Initialization

    private override init() {
        super.init()
        configureRevenueCat()
    }

    // MARK: - Configuration

    private func configureRevenueCat() {
        guard !apiKey.contains("YOUR_") else {
            print("⚠️ RevenueCatService: API key not configured. Please add your RevenueCat API key.")
            errorMessage = "RevenueCat API key not configured"
            return
        }

        if BuildLogging.isEnabled {
            Purchases.logLevel = .debug
        }

        Purchases.configure(
            with: Configuration.Builder(withAPIKey: apiKey)
                .with(storeKitVersion: .storeKit2)
                .with(appUserID: appUserID)
                .build()
        )

        Purchases.shared.delegate = self

        isInitialized = true
        print("✅ RevenueCatService: SDK initialized successfully")

        Task {
            await syncCustomerInfo()
            await loadOfferings()
        }
    }

    // MARK: - Customer Info Sync

    func syncCustomerInfo() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await updateCustomerInfo(customerInfo)
        } catch {
            print("❌ RevenueCatService: Error syncing customer info - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    /// Applies RevenueCat’s cached ``CustomerInfo`` synchronously so the first UI frame can show Pro before the first network refresh (when a cache exists).
    func applyCachedCustomerInfoIfAvailable() {
        guard isInitialized else { return }
        guard let cached = Purchases.shared.cachedCustomerInfo else { return }
        customerInfo = cached
        let hasPremium = cached.entitlements[premiumEntitlementID]?.isActive == true
        activeEntitlements = Set(cached.entitlements.active.keys)
        isPremiumActive = hasPremium
    }

    /// Called from async entry points and ``PurchasesDelegate`` (hop to main actor in delegate).
    func updateCustomerInfo(_ customerInfo: CustomerInfo) async {
        self.customerInfo = customerInfo

        let hasPremium = customerInfo.entitlements[premiumEntitlementID]?.isActive == true
        let activeEntitlements = Set(customerInfo.entitlements.active.keys)

        isPremiumActive = hasPremium
        self.activeEntitlements = activeEntitlements

        print("✅ RevenueCatService: Customer info updated - Premium: \(hasPremium)")
    }

    // MARK: - User Identification

    func identifyUser(userID: String) async throws {
        let (customerInfo, created) = try await Purchases.shared.logIn(userID)
        await updateCustomerInfo(customerInfo)
        if created {
            print("✅ RevenueCatService: New user created - \(userID)")
        } else {
            print("✅ RevenueCatService: User identified - \(userID)")
        }
    }

    func logOut() async throws {
        let customerInfo = try await Purchases.shared.logOut()
        await updateCustomerInfo(customerInfo)
        print("✅ RevenueCatService: User logged out")
    }

    // MARK: - Offerings & Products

    func getOfferings() async throws -> Offerings {
        let offerings = try await Purchases.shared.offerings()
        self.offerings = offerings
        currentOffering = offerings.current
        return offerings
    }

    func getCurrentOffering() async throws -> Offering? {
        if let currentOffering {
            return currentOffering
        }

        let offerings = try await getOfferings()
        return offerings.current
    }

    func loadOfferings() async {
        isLoadingOfferings = true
        errorMessage = nil

        do {
            _ = try await getOfferings()
            isLoadingOfferings = false
            print("✅ RevenueCatService: Offerings loaded successfully")
        } catch {
            errorMessage = "Failed to load offerings: \(error.localizedDescription)"
            isLoadingOfferings = false
            print("❌ RevenueCatService: Error loading offerings - \(error.localizedDescription)")
        }
    }

    func getPackage(identifier: String) -> Package? {
        currentOffering?.package(identifier: identifier)
    }

    func getAvailablePackages() -> [Package] {
        currentOffering?.availablePackages ?? []
    }

    // MARK: - Purchase Management

    func purchase(package: Package) async throws -> (CustomerInfo, Bool) {
        let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)

        await updateCustomerInfo(customerInfo)

        if userCancelled {
            throw RevenueCatError.userCancelled
        }

        print("✅ RevenueCatService: Purchase successful - \(package.storeProduct.productIdentifier)")
        return (customerInfo, userCancelled)
    }

    func purchase(productIdentifier: String) async throws -> CustomerInfo {
        guard let offering = try await getCurrentOffering() else {
            throw RevenueCatError.purchaseFailed("No offering available")
        }

        if let package = offering.package(identifier: productIdentifier) {
            let (customerInfo, userCancelled) = try await purchase(package: package)
            if userCancelled {
                throw RevenueCatError.userCancelled
            }
            return customerInfo
        }

        if let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == productIdentifier }) {
            let (customerInfo, userCancelled) = try await purchase(package: package)
            if userCancelled {
                throw RevenueCatError.userCancelled
            }
            return customerInfo
        }

        throw RevenueCatError.packageNotFound(productIdentifier)
    }

    func restorePurchases() async throws {
        let customerInfo = try await Purchases.shared.restorePurchases()
        await updateCustomerInfo(customerInfo)
        print("✅ RevenueCatService: Purchases restored")
    }

    var canMakePurchases: Bool {
        Purchases.canMakePayments()
    }

    // MARK: - Subscription Status

    var hasActivePremium: Bool {
        isPremiumActive
    }

    func checkEntitlement(_ entitlementID: String = "premium") async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            return customerInfo.entitlements.all[entitlementID]?.isActive == true
        } catch {
            print("❌ RevenueCatService: Error checking entitlement - \(error.localizedDescription)")
            return false
        }
    }

    var activeProductID: String? {
        guard let customerInfo = customerInfo,
              let entitlement = customerInfo.entitlements[premiumEntitlementID],
              entitlement.isActive else {
            return nil
        }
        return entitlement.productIdentifier
    }

    var premiumExpirationDate: Date? {
        guard let customerInfo = customerInfo,
              let entitlement = customerInfo.entitlements[premiumEntitlementID],
              entitlement.isActive else {
            return nil
        }
        return entitlement.expirationDate
    }

    // MARK: - Debug Helpers

    #if DEBUG || LOGGING
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

    var isInGracePeriod: Bool {
        guard let customerInfo = customerInfo,
              let entitlement = customerInfo.entitlements[premiumEntitlementID] else {
            return false
        }
        return entitlement.isActive && !entitlement.willRenew && entitlement.expirationDate != nil
    }

    var latestTransactionDate: Date? {
        customerInfo?.latestExpirationDate
    }

    var firstSeenDate: Date? {
        customerInfo?.firstSeen
    }
}
