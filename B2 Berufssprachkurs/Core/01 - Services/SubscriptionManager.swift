//
//  SubscriptionManager.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//  Updated to use RevenueCat while maintaining backward compatibility
//

import Foundation
import StoreKit
import Combine
import RevenueCat

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // Product IDs from App Store Connect
    private let productIDs = [
        "hero.premium.monthly",
        "hero.premium.quarterly",
        "hero.premium.lifetime.promo",
        "hero.premium.lifetime"
    ]
    
    // Published properties for UI observation
    @Published var isPremiumActive = false
    @Published var hasActiveSubscription = false // Separate from trial
    @Published var activeProductID: String? = nil // Track which product is currently active
    @Published var isLoading = false
    @Published var purchaseState: PurchaseState = .idle
    @Published var products: [String: Product] = [:]
    @Published var errorMessage: String?
    
    // RevenueCat service (primary source of truth)
    private let revenueCatService = RevenueCatService.shared
    
    // Combine cancellables for syncing
    private var cancellables = Set<AnyCancellable>()
    
    // Check if active subscription is lifetime
    var hasLifetimeSubscription: Bool {
        return activeProductID == "hero.premium.lifetime" || activeProductID == "hero.premium.lifetime.promo"
    }
    
    // Convenience property for backward compatibility (defaults to monthly)
    var product: Product? {
        products["hero.premium.monthly"]
    }
    
    // Trial period constants
    private let trialPeriodDays: TimeInterval = 3 * 24 * 60 * 60 // 3 days in seconds
    private let firstLaunchDateKey = "firstLaunchDate"
    private let trialActivatedKey = "trialActivated"
    
    // Private initialization
    private init() {
        // Initialize 3-day trial for new users (but don't auto-activate)
        // Trial will be activated when user taps "Start Free Trial" button
        initializeTrialIfNeeded()
        
        // Sync with RevenueCat service
        setupRevenueCatSync()
        
        // Load products and check subscription status
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    // MARK: - RevenueCat Integration
    
    /// Sets up syncing with RevenueCat service
    private func setupRevenueCatSync() {
        // Sync premium status from RevenueCat
        revenueCatService.$isPremiumActive
            .dropFirst()
            .sink { [weak self] isPremium in
                Task { @MainActor [weak self] in
                    await self?.updateFromRevenueCat()
                }
            }
            .store(in: &cancellables)
        
        // Sync when customer info updates
        revenueCatService.$customerInfo
            .compactMap { $0 }
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.updateFromRevenueCat()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Updates subscription status from RevenueCat
    private func updateFromRevenueCat() async {
        // Update premium status from RevenueCat (but preserve trial status)
        let revenueCatPremium = revenueCatService.isPremiumActive
        let trialActive = isTrialActive()
        
        // Premium is active if RevenueCat says so OR trial is active
        isPremiumActive = revenueCatPremium || trialActive
        
        // Update active subscription status (exclude trial)
        hasActiveSubscription = revenueCatPremium
        
        // Update active product ID from RevenueCat
        activeProductID = revenueCatService.activeProductID
    }
    
    // MARK: - Purchase State
    
    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case success
        case failed(String)
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load offerings from RevenueCat
            let offerings = try await revenueCatService.getOfferings()
            
            // Map RevenueCat packages to StoreKit Products for backward compatibility
            var productsDict: [String: Product] = [:]
            
            if let currentOffering = offerings.current {
                for package in currentOffering.availablePackages {
                    let storeProduct = package.storeProduct
                    // Map to StoreKit Product format for backward compatibility
                    if let product = try? await Product.products(for: [storeProduct.productIdentifier]).first {
                        productsDict[storeProduct.productIdentifier] = product
                    } else {
                        // Fallback: Create a Product wrapper from StoreProduct if needed
                        // Note: This is a simplified mapping - full Product API may not be available
                        print("SubscriptionManager: Could not load StoreKit Product for \(storeProduct.productIdentifier)")
                    }
                }
            }
            
            // Fallback: Also try loading directly from StoreKit for products not in offerings
            let directProducts = try await Product.products(for: productIDs)
            for product in directProducts {
                if productsDict[product.id] == nil {
                    productsDict[product.id] = product
                }
            }
            
            self.products = productsDict
            
            // Update subscription status after loading products
            await checkSubscriptionStatus()
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("SubscriptionManager: Error loading products - \(error)")
            
            // Fallback to direct StoreKit loading if RevenueCat fails
            do {
                let loadedProducts = try await Product.products(for: productIDs)
                var productsDict: [String: Product] = [:]
                for product in loadedProducts {
                    productsDict[product.id] = product
                }
                self.products = productsDict
            } catch {
                print("SubscriptionManager: Fallback StoreKit loading also failed - \(error)")
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Check Subscription Status
    
    func checkSubscriptionStatus() async {
        // Primary: Check RevenueCat entitlements
        await revenueCatService.syncCustomerInfo()
        await updateFromRevenueCat()
        
        // Fallback: Also check StoreKit directly for redundancy
        var hasStoreKitSubscription = false
        var storeKitProductID: String? = nil
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if this transaction is for any of our products
                if productIDs.contains(transaction.productID) {
                    hasStoreKitSubscription = true
                    storeKitProductID = transaction.productID
                    break
                }
            } catch {
                print("SubscriptionManager: Error verifying transaction - \(error)")
            }
        }
        
        // Use RevenueCat as primary source, StoreKit as fallback
        if !hasActiveSubscription && hasStoreKitSubscription {
            hasActiveSubscription = true
            activeProductID = storeKitProductID
        }
        
        // Premium is active if subscription is active OR trial is active
        let trialActive = isTrialActive()
        isPremiumActive = hasActiveSubscription || trialActive
    }
    
    // MARK: - Purchase Subscription
    
    func purchaseSubscription(productID: String? = nil) async throws {
        // Use provided productID or default to monthly
        let targetProductID = productID ?? "hero.premium.monthly"
        
        purchaseState = .purchasing
        
        do {
            // Primary: Use RevenueCat for purchase
            _ = try await revenueCatService.purchase(productIdentifier: targetProductID)
            
            // Update subscription status
            await updateFromRevenueCat()
            purchaseState = .success
            
            // Verify subscription status again
            await checkSubscriptionStatus()
            
        } catch RevenueCatError.userCancelled {
            purchaseState = .idle
            throw SubscriptionError.userCancelled
        } catch {
            // Fallback to StoreKit if RevenueCat fails
            guard let product = products[targetProductID] else {
                purchaseState = .failed("Product not available")
                throw SubscriptionError.productNotLoaded
            }
            
            do {
                let result = try await product.purchase()
                
                switch result {
                case .success(let verification):
                    let transaction = try checkVerified(verification)
                    
                    // Update subscription status
                    hasActiveSubscription = true
                    isPremiumActive = true
                    purchaseState = .success
                    
                    // Finish the transaction
                    await transaction.finish()
                    
                    // Verify subscription status again
                    await checkSubscriptionStatus()
                    
                case .userCancelled:
                    purchaseState = .idle
                    throw SubscriptionError.userCancelled
                    
                case .pending:
                    purchaseState = .loading
                    // Transaction is pending (e.g., waiting for approval)
                    
                @unknown default:
                    purchaseState = .failed("Unknown purchase result")
                    throw SubscriptionError.unknown
                }
            } catch {
                purchaseState = .failed(error.localizedDescription)
                errorMessage = error.localizedDescription
                throw error
            }
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Primary: Use RevenueCat to restore purchases
            try await revenueCatService.restorePurchases()
            await updateFromRevenueCat()
        } catch {
            print("SubscriptionManager: RevenueCat restore failed, trying StoreKit - \(error)")
            // Fallback: Check StoreKit directly
            await checkSubscriptionStatus()
        }
        
        isLoading = false
        
        if isPremiumActive {
            // Purchases restored successfully
            HapticManager.shared.success()
        } else {
            // No active subscription found
            errorMessage = "No active subscription found"
            HapticManager.shared.warning()
        }
    }
    
    // MARK: - Transaction Listener (Legacy - RevenueCat handles this now)
    
    // Note: RevenueCat handles transaction updates via its delegate
    // This method is kept for backward compatibility but is no longer actively used
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Update subscription status if this is one of our products
                    if self.productIDs.contains(transaction.productID) {
                        // RevenueCat will handle this via delegate, but update here as fallback
                        await Task { @MainActor in
                            await self.checkSubscriptionStatus()
                        }.value
                    }
                    
                    // Always finish the transaction
                    await transaction.finish()
                } catch {
                    print("SubscriptionManager: Transaction verification failed - \(error)")
                }
            }
        }
    }
    
    // MARK: - Transaction Verification
    
    private func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.transactionUnverified
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - 3-Day Free Trial
    
    // Check if user has ever activated the trial
    var hasUsedTrial: Bool {
        UserDefaults.standard.bool(forKey: trialActivatedKey)
    }
    
    
    // Activate trial when user taps "Start Free Trial"
    func activateTrial() {
        let userDefaults = UserDefaults.standard
        
        // Only activate if trial hasn't been used before
        guard !userDefaults.bool(forKey: trialActivatedKey) else {
            return
        }
        
        // Activate 3-day trial
        let now = Date()
        userDefaults.set(now.timeIntervalSince1970, forKey: firstLaunchDateKey)
        userDefaults.set(true, forKey: trialActivatedKey)
        
        print("SubscriptionManager: 3-day free trial activated")
        
        // Update premium status immediately
        isPremiumActive = true
    }
    
    private func initializeTrialIfNeeded() {
        let userDefaults = UserDefaults.standard
        
        // Check if trial has already been activated
        if userDefaults.bool(forKey: trialActivatedKey) {
            // Trial was already activated, check if it's still active
            updatePremiumStatusFromTrial()
            return
        }
        
        // Don't auto-activate trial - user must tap "Start Free Trial" button
        // Just mark first launch date for tracking
        if userDefaults.object(forKey: firstLaunchDateKey) == nil {
            let now = Date()
            userDefaults.set(now.timeIntervalSince1970, forKey: firstLaunchDateKey)
        }
    }
    
    private func isTrialActive() -> Bool {
        let userDefaults = UserDefaults.standard
        
        // Check if trial was activated
        guard userDefaults.bool(forKey: trialActivatedKey) else {
            return false
        }
        
        // Get first launch date
        guard let firstLaunchTimestamp = userDefaults.object(forKey: firstLaunchDateKey) as? TimeInterval else {
            return false
        }
        
        let firstLaunchDate = Date(timeIntervalSince1970: firstLaunchTimestamp)
        let trialEndDate = firstLaunchDate.addingTimeInterval(trialPeriodDays)
        let now = Date()
        
        // Trial is active if current date is before trial end date
        return now < trialEndDate
    }
    
    private func updatePremiumStatusFromTrial() {
        // Check if trial is active and update premium status accordingly
        let trialActive = isTrialActive()
        
        // Only update if we don't already have a subscription
        if trialActive {
            // Check subscription status in background, but set trial immediately
            Task {
                await checkSubscriptionStatus()
            }
            // Set premium to true immediately if trial is active
            if !isPremiumActive {
                isPremiumActive = true
            }
        } else {
            // Trial expired, check if we have subscription
            Task {
                await checkSubscriptionStatus()
            }
        }
    }
    
    // MARK: - Debug: Deactivate Premium (Testing Only)
    
    func deactivatePremiumForTesting() {
        // Clear trial activation
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: trialActivatedKey)
        userDefaults.removeObject(forKey: firstLaunchDateKey)
        
        // Clear subscription status
        isPremiumActive = false
        
        // Recheck subscription status (this will remain false if no active subscription)
        Task {
            await checkSubscriptionStatus()
        }
        
        print("SubscriptionManager: Premium deactivated for testing")
    }

    /// Debug helper to force-enable premium state via trial activation.
    /// This keeps behavior local and reversible for QA flows.
    func activatePremiumForTesting() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(Date().timeIntervalSince1970, forKey: firstLaunchDateKey)
        userDefaults.set(true, forKey: trialActivatedKey)

        isPremiumActive = true
        hasActiveSubscription = false
        activeProductID = nil

        print("SubscriptionManager: Premium activated for testing")
    }

    /// Clears local trial keys used by debug / trial flows, then re-syncs premium from RevenueCat and StoreKit so the app matches normal production behavior.
    func restoreNormalSubscriptionStateForTesting() async {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: trialActivatedKey)
        userDefaults.removeObject(forKey: firstLaunchDateKey)

        await checkSubscriptionStatus()

        print("SubscriptionManager: Restored normal subscription state (store sync)")
    }
    
    // MARK: - Debug: Reset to Fresh Install State
    
    func resetToFreshInstall() {
        let userDefaults = UserDefaults.standard
        
        // Clear all trial and premium related keys
        userDefaults.removeObject(forKey: trialActivatedKey)
        userDefaults.removeObject(forKey: firstLaunchDateKey)
        // Reset subscription status
        isPremiumActive = false
        hasActiveSubscription = false
        activeProductID = nil
        
        // Recheck subscription status
        Task {
            await checkSubscriptionStatus()
        }
        
        print("SubscriptionManager: Reset to fresh install state")
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case productNotLoaded
    case userCancelled
    case transactionUnverified
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotLoaded:
            return "Product information is not available. Please try again."
        case .userCancelled:
            return "Purchase was cancelled."
        case .transactionUnverified:
            return "Transaction could not be verified."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

