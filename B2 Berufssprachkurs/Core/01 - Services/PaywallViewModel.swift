//
//  PaywallViewModel.swift
//  B2 Berufssprachkurs
//
//  View model driving paywall products, selection, and purchase actions.
//  Created: 04.04.26.
//

import Combine
import Foundation
import RevenueCat

// MARK: - PaywallViewModel

@MainActor
final class PaywallViewModel: ObservableObject {
    let revenueCatService: RevenueCatService
    let subscriptionManager: SubscriptionManager

    @Published var selectedProductID: String
    @Published var selectedPackage: Package?
    @Published var isLoadingPackages = false
    @Published var isLaunchOfferActive = false
    @Published var countdownString = ""
    @Published var showingError = false
    @Published var errorMessage: String?
    @Published var presentingLegalURL: URL?

    private var launchOfferTick: AnyCancellable?

    init() {
        self.revenueCatService = RevenueCatService.shared
        self.subscriptionManager = SubscriptionManager.shared
        self.selectedProductID = PaywallProductID.yearly.rawValue
        self.isLaunchOfferActive = LaunchOfferService.isLaunchOfferActive
        self.countdownString = LaunchOfferService.isLaunchOfferActive ? LaunchOfferService.countdownString : ""
    }

    deinit {
        launchOfferTick?.cancel()
    }

    /// Starts one-second updates for launch-offer countdown (replaces `Timer` in the view).
    func startLaunchOfferTimer() {
        guard launchOfferTick == nil else { return }
        launchOfferTick = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickLaunchOffer()
            }
    }

    func stopLaunchOfferTimer() {
        launchOfferTick?.cancel()
        launchOfferTick = nil
    }

    private func tickLaunchOffer() {
        let activeNow = LaunchOfferService.isLaunchOfferActive
        if activeNow != isLaunchOfferActive {
            isLaunchOfferActive = activeNow
            if !activeNow && selectedProductID == PaywallProductID.lifetimePromo.rawValue {
                selectedProductID = PaywallProductID.yearly.rawValue
                updateSelectedPackage()
            }
        }
        countdownString = activeNow ? LaunchOfferService.countdownString : ""
    }

    func loadOfferingsAndProducts() async {
        if revenueCatService.currentOffering == nil {
            isLoadingPackages = true
            await revenueCatService.loadOfferings()
            isLoadingPackages = false
        }
        if subscriptionManager.products.isEmpty {
            await subscriptionManager.loadProducts()
        }
        isLaunchOfferActive = LaunchOfferService.isLaunchOfferActive
        selectedProductID = PaywallProductID.yearly.rawValue
        countdownString = isLaunchOfferActive ? LaunchOfferService.countdownString : ""
        updateSelectedPackage()
    }

    func selectProduct(_ productID: String) {
        selectedProductID = productID
        updateSelectedPackage()
    }

    func updateSelectedPackage() {
        guard let offering = revenueCatService.currentOffering else {
            selectedPackage = nil
            return
        }
        selectedPackage = offering.availablePackages.first { $0.storeProduct.productIdentifier == selectedProductID }
    }

    var isPrimaryButtonEnabled: Bool {
        let hasPackage = selectedPackage != nil
        let hasProduct = subscriptionManager.products[selectedProductID] != nil
        let isNotLoading = !isLoadingPackages && !subscriptionManager.isLoading
        let isNotPurchasing = subscriptionManager.purchaseState != .purchasing && subscriptionManager.purchaseState != .loading
        return isNotLoading && (hasPackage || hasProduct) && isNotPurchasing
    }

    /// Returns `true` if the user has Hero Pro after purchase (RevenueCat or StoreKit path).
    func purchase() async -> Bool {
        HapticManager.shared.mediumImpact()

        if let package = selectedPackage {
            do {
                _ = try await revenueCatService.purchase(package: package)
                await subscriptionManager.checkSubscriptionStatus()
                return isPremiumNow()
            } catch RevenueCatError.userCancelled {
                return false
            } catch {
                do {
                    try await subscriptionManager.purchaseSubscription(productID: selectedProductID)
                    await subscriptionManager.checkSubscriptionStatus()
                    return isPremiumNow()
                } catch SubscriptionError.userCancelled {
                    return false
                } catch {
                    showingError = true
                    errorMessage = error.localizedDescription
                    return false
                }
            }
        } else {
            do {
                try await subscriptionManager.purchaseSubscription(productID: selectedProductID)
                await subscriptionManager.checkSubscriptionStatus()
                return isPremiumNow()
            } catch SubscriptionError.userCancelled {
                return false
            } catch {
                showingError = true
                errorMessage = error.localizedDescription
                return false
            }
        }
    }

    func restorePurchases() async {
        HapticManager.shared.lightImpact()
        await subscriptionManager.restorePurchases()
    }

    private func isPremiumNow() -> Bool {
        subscriptionManager.isPremiumActive || revenueCatService.isPremiumActive
    }
}
