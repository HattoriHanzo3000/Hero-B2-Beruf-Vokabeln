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

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    let productIDs = PaywallProductID.allProductIDs
    let revenueCatService = RevenueCatService.shared

    @Published var isPremiumActive = false
    @Published var hasActiveSubscription = false
    @Published var activeProductID: String?
    @Published var isLoading = false
    @Published var purchaseState: PurchaseState = .idle
    @Published var products: [String: Product] = [:]
    @Published var errorMessage: String?
    /// After first ``checkSubscriptionStatus()`` at launch so free-tier CTAs don’t flash for subscribers.
    @Published private(set) var hasCompletedInitialSubscriptionSync = false

    private var cancellables = Set<AnyCancellable>()

    var hasLifetimeSubscription: Bool {
        guard let id = activeProductID else { return false }
        return PaywallProductID.usesLifetimeTerms(productIdentifier: id)
    }

    var premiumExpirationDate: Date? {
        revenueCatService.premiumExpirationDate
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
            hasCompletedInitialSubscriptionSync = true
            await loadProducts()
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
        applyPremiumFlagsFromRevenueCatAndTrial()
    }

    private func applyPremiumFlagsFromRevenueCatAndTrial() {
        let revenueCatPremium = revenueCatService.isPremiumActive
        let trialActive = isTrialActive()
        isPremiumActive = revenueCatPremium || trialActive
        hasActiveSubscription = revenueCatPremium
        activeProductID = revenueCatService.activeProductID
    }

    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchasing
        case success
        case failed(String)
    }
}
