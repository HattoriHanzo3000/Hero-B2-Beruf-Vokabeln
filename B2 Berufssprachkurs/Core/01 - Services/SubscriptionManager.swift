//
//  SubscriptionManager.swift
//  B2 Berufssprachkurs
//
//  Premium state: RevenueCat (primary), StoreKit 2 (products / fallback), local 3-day trial.
//

import Combine
import Foundation
import RevenueCat
import StoreKit
import SwiftUI

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @AppStorage("lastKnownPremiumState") private var lastKnownPremiumState = false

    let productIDs = PaywallProductID.allProductIDs
    let revenueCatService = RevenueCatService.shared

    @Published var isPremiumActive = false
    @Published var hasActiveSubscription = false
    @Published var activeProductID: String?
    @Published var isLoading = false
    @Published var purchaseState: PurchaseState = .idle
    @Published var products: [String: Product] = [:]
    @Published var errorMessage: String?
    /// Shared restore feedback for all entry points (Paywall, Your Plan).
    @Published var showRestoreFeedbackAlert = false
    @Published var restoreFeedbackMessage: String?
    /// Latest expiration observed from verified StoreKit entitlement scan.
    @Published private(set) var storeKitExpirationDate: Date?
    /// After first ``checkSubscriptionStatus()`` at launch so free-tier CTAs don’t flash for subscribers.
    @Published private(set) var hasCompletedInitialSubscriptionSync = false

    private var cancellables = Set<AnyCancellable>()

    var hasLifetimeSubscription: Bool {
        guard let id = activeProductID else { return false }
        return PaywallProductID.usesLifetimeTerms(productIdentifier: id)
    }

    var premiumExpirationDate: Date? {
        revenueCatService.premiumExpirationDate ?? storeKitExpirationDate
    }

    var product: Product? {
        products[PaywallProductID.monthly.rawValue]
    }

    private init() {
        initializeTrialIfNeeded()
        setupRevenueCatSync()

        revenueCatService.applyCachedCustomerInfoIfAvailable()
        applyPremiumFlagsFromRevenueCatAndTrial()

        Task { @MainActor in
            await checkSubscriptionStatus()
            await loadProducts()
            hasCompletedInitialSubscriptionSync = true
        }
    }

    // MARK: - RevenueCat

    private func setupRevenueCatSync() {
        revenueCatService.$isPremiumActive
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.updateFromRevenueCat()
                }
            }
            .store(in: &cancellables)

        revenueCatService.$customerInfo
            .compactMap { $0 }
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.updateFromRevenueCat()
                }
            }
            .store(in: &cancellables)
    }

    func updateFromRevenueCat() async {
        let storeKit = await currentStoreKitEntitlementSnapshot()
        applyMergedEntitlementState(
            revenueCatPremium: revenueCatService.isPremiumActive,
            revenueCatProductID: revenueCatService.activeProductID,
            storeKit: storeKit
        )
    }

    private func applyPremiumFlagsFromRevenueCatAndTrial() {
        let revenueCatPremium = revenueCatService.isPremiumActive
        let trialActive = isTrialActive()
        isPremiumActive = revenueCatPremium || trialActive
        // Prevent overwriting a valid 'true' cache with 'false' during cold start
        // before RevenueCat has fully loaded its data.
        if hasCompletedInitialSubscriptionSync || isPremiumActive {
            lastKnownPremiumState = isPremiumActive
        }
        hasActiveSubscription = revenueCatPremium
        activeProductID = revenueCatService.activeProductID
    }

    func applyMergedEntitlementState(
        revenueCatPremium: Bool,
        revenueCatProductID: String?,
        storeKit: StoreKitEntitlementSnapshot
    ) {
        hasActiveSubscription = revenueCatPremium || storeKit.hasActiveSubscription
        activeProductID = revenueCatProductID ?? storeKit.activeProductID
        storeKitExpirationDate = storeKit.expirationDate

        let trialActive = isTrialActive()
        isPremiumActive = hasActiveSubscription || trialActive
        lastKnownPremiumState = isPremiumActive
    }

    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case success
        case failed(String)
    }
}
