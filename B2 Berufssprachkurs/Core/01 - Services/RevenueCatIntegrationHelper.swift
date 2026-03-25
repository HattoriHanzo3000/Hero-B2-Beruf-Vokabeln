//
//  RevenueCatIntegrationHelper.swift
//  B2 Berufssprachkurs
//
//  Helper to integrate RevenueCat with existing SubscriptionManager
//

import Foundation
import Combine

/// Helper class to sync RevenueCat with existing SubscriptionManager
@MainActor
final class RevenueCatIntegrationHelper: ObservableObject {
    static let shared = RevenueCatIntegrationHelper()
    
    private let revenueCatService = RevenueCatService.shared
    private let subscriptionManager = SubscriptionManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSync()
    }
    
    // MARK: - Setup Sync
    
    /// Sets up automatic syncing between RevenueCat and SubscriptionManager
    private func setupSync() {
        // Sync when RevenueCat premium status changes
        revenueCatService.$isPremiumActive
            .dropFirst() // Skip initial value
            .sink { [weak self] isPremium in
                Task { [weak self] in
                    await self?.syncPremiumStatus(isPremium)
                }
            }
            .store(in: &cancellables)
        
        // Sync when SubscriptionManager premium status changes
        subscriptionManager.$isPremiumActive
            .dropFirst() // Skip initial value
            .sink { [weak self] isPremium in
                Task { [weak self] in
                    await self?.syncToRevenueCat(isPremium)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sync Methods
    
    /// Syncs premium status from RevenueCat to SubscriptionManager
    private func syncPremiumStatus(_ isPremium: Bool) async {
        // Only update if different to avoid loops
        if subscriptionManager.isPremiumActive != isPremium {
            // Note: We don't directly set isPremiumActive on SubscriptionManager
            // Instead, we trigger a status check which will update it based on StoreKit
            await subscriptionManager.checkSubscriptionStatus()
        }
    }
    
    /// Syncs premium status to RevenueCat (if needed)
    private func syncToRevenueCat(_ isPremium: Bool) async {
        // RevenueCat should already be in sync via its own StoreKit integration
        // This is mainly for logging/debugging
        if revenueCatService.isPremiumActive != isPremium {
            // Trigger a customer info sync
            await revenueCatService.syncCustomerInfo()
        }
    }
    
    // MARK: - Manual Sync
    
    /// Manually syncs both services
    func syncBothServices() async {
        await subscriptionManager.checkSubscriptionStatus()
        await revenueCatService.syncCustomerInfo()
    }
    
    /// Gets the most accurate premium status (checks both services)
    var isPremiumActive: Bool {
        // Prefer RevenueCat as it's the source of truth for entitlements
        return revenueCatService.isPremiumActive || subscriptionManager.isPremiumActive
    }
}
