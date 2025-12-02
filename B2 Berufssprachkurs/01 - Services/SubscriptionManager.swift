//
//  SubscriptionManager.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import Foundation
import StoreKit
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // Product ID from App Store Connect
    private let productID = "monthly_1.99_3d_trial"
    
    // Published properties for UI observation
    @Published var isPremiumActive = false
    @Published var isLoading = false
    @Published var purchaseState: PurchaseState = .idle
    @Published var product: Product?
    @Published var errorMessage: String?
    
    // StoreKit transaction listener
    private var updateListenerTask: Task<Void, Error>?
    
    // Trial period constants
    private let trialPeriodDays: TimeInterval = 3 * 24 * 60 * 60 // 3 days in seconds
    private let firstLaunchDateKey = "firstLaunchDate"
    private let trialActivatedKey = "trialActivated"
    
    // Private initialization
    private init() {
        // Initialize 3-day trial for new users
        initializeTrialIfNeeded()
        
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Check current subscription status
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
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
            let products = try await Product.products(for: [productID])
            
            if let product = products.first {
                self.product = product
                
                // Update subscription status after loading product
                await checkSubscriptionStatus()
            } else {
                errorMessage = "Product not found in App Store Connect"
            }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("SubscriptionManager: Error loading products - \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Check Subscription Status
    
    func checkSubscriptionStatus() async {
        // Check subscription entitlements
        var hasSubscription = false
        
        if product != nil {
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    
                    // Check if this transaction is for our product
                    if transaction.productID == productID {
                        hasSubscription = true
                        break
                    }
                } catch {
                    print("SubscriptionManager: Error verifying transaction - \(error)")
                }
            }
        }
        
        // Premium is active if subscription is active OR trial is active
        isPremiumActive = hasSubscription || isTrialActive()
    }
    
    // MARK: - Purchase Subscription
    
    func purchaseSubscription() async throws {
        guard let product = product else {
            throw SubscriptionError.productNotLoaded
        }
        
        purchaseState = .purchasing
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Update subscription status
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
                // We'll be notified via transaction listener
                
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
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        // Check current entitlements
        await checkSubscriptionStatus()
        
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
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }
                
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Update subscription status if this is our product
                    if transaction.productID == self.productID {
                        await MainActor.run {
                            self.isPremiumActive = true
                        }
                    }
                    
                    // Always finish the transaction
                    await transaction.finish()
                    
                    // Recheck subscription status on main actor
                    await self.checkSubscriptionStatus()
                } catch {
                    print("SubscriptionManager: Transaction verification failed - \(error)")
                }
            }
        }
    }
    
    // MARK: - Transaction Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.transactionUnverified
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - 3-Day Free Trial
    
    private func initializeTrialIfNeeded() {
        let userDefaults = UserDefaults.standard
        
        // Check if trial has already been activated
        if userDefaults.bool(forKey: trialActivatedKey) {
            // Trial was already activated, check if it's still active
            updatePremiumStatusFromTrial()
            return
        }
        
        // Check if this is the first launch
        if userDefaults.object(forKey: firstLaunchDateKey) == nil {
            // First launch - activate 3-day trial
            let now = Date()
            userDefaults.set(now.timeIntervalSince1970, forKey: firstLaunchDateKey)
            userDefaults.set(true, forKey: trialActivatedKey)
            
            print("SubscriptionManager: 3-day free trial activated for new user")
            
            // Update premium status immediately (trial is now active)
            isPremiumActive = true
        } else {
            // Not first launch, check if trial is still active
            updatePremiumStatusFromTrial()
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
        // This is called synchronously to provide immediate feedback
        let trialActive = isTrialActive()
        
        // Only update if we don't already have a subscription
        // If we have subscription, checkSubscriptionStatus will handle it
        if trialActive {
            // Check subscription status in background, but set trial immediately
            Task {
                await checkSubscriptionStatus()
            }
            // Set premium to true immediately if trial is active
            // checkSubscriptionStatus will refine this if subscription exists
            if !isPremiumActive {
                isPremiumActive = true
            }
        }
    }
    
    // MARK: - Debug: Deactivate Premium (Testing Only)
    
    func deactivatePremiumForTesting() {
        // Clear trial activation
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: trialActivatedKey)
        userDefaults.removeObject(forKey: firstLaunchDateKey)
        
        // Clear temporary premium unlocks
        userDefaults.removeObject(forKey: "premiumUnlockedUntil")
        userDefaults.removeObject(forKey: "adsDisabledUntil")
        
        // Clear promo code premium
        PromoCodeManager.shared.clearPromoCodes()
        
        // Clear subscription status
        isPremiumActive = false
        
        // Recheck subscription status (this will remain false if no active subscription)
        Task {
            await checkSubscriptionStatus()
        }
        
        print("SubscriptionManager: Premium deactivated for testing")
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

