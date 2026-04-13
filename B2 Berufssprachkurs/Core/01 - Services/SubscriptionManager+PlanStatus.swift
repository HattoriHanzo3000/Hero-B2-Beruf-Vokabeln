//
//  SubscriptionManager+PlanStatus.swift
//  B2 Berufssprachkurs
//
//  Derived plan status strings and subscription presentation helpers.
//  Created: 06.04.26.
//

import Foundation

// MARK: - SubscriptionManager

extension SubscriptionManager {
    /// One-line localized plan label for Settings and Your Plan.
    var localizedPlanStatusLine: String {
        if !hasCompletedInitialSubscriptionSync {
            return Localizable.string(Localizable.planStatusLoading)
        }
        if !isPremiumActive {
            return Localizable.string(Localizable.planStatusFree)
        }
        if hasLifetimeSubscription {
            return Localizable.string(Localizable.planStatusLifetime)
        }
        if hasActiveSubscription {
            switch activeProductID {
            case PaywallProductID.monthly.rawValue:
                return Localizable.string(Localizable.planStatusMonthly)
            case PaywallProductID.yearly.rawValue:
                return Localizable.string(Localizable.planStatusYearly)
            default:
                return Localizable.string(Localizable.planStatusHeroProActive)
            }
        }
        if isLocalTrialActive {
            return Localizable.string(Localizable.planStatusTrial)
        }
        return Localizable.string(Localizable.planStatusHeroProActive)
    }
}
