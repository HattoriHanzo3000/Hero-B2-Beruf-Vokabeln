//
//  SubscriptionManager+Debug.swift
//  B2 Berufssprachkurs
//
//  Debug utilities and previews for subscription scenarios.
//  Created: 06.04.26.
//

import Foundation

#if DEBUG || LOGGING

// MARK: - SubscriptionManager

extension SubscriptionManager {
    func deactivatePremiumForTesting() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: TrialKeys.trialActivatedKey)
        userDefaults.removeObject(forKey: TrialKeys.firstLaunchDateKey)
        userDefaults.removeObject(forKey: TrialKeys.firstAppOpenForLaunchOfferKey)

        DebugOverrides.simulatePro = false
        isPremiumActive = false

        Task {
            await checkSubscriptionStatus()
        }

        print("SubscriptionManager: Premium deactivated for testing")
    }

    /// Debug helper to force-enable premium state via trial activation.
    func activatePremiumForTesting() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: TrialKeys.trialActivatedKey)
        userDefaults.removeObject(forKey: TrialKeys.firstLaunchDateKey)
        userDefaults.removeObject(forKey: TrialKeys.firstAppOpenForLaunchOfferKey)

        DebugOverrides.simulatePro = true
        isPremiumActive = true
        hasActiveSubscription = false
        activeProductID = nil

        print("SubscriptionManager: Premium activated for testing")
    }

    /// Clears local trial keys, then re-syncs premium from RevenueCat and StoreKit.
    func restoreNormalSubscriptionStateForTesting() async {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: TrialKeys.trialActivatedKey)
        userDefaults.removeObject(forKey: TrialKeys.firstLaunchDateKey)
        userDefaults.removeObject(forKey: TrialKeys.firstAppOpenForLaunchOfferKey)

        DebugOverrides.simulatePro = nil
        await checkSubscriptionStatus()

        print("SubscriptionManager: Restored normal subscription state (store sync)")
    }

    func resetToFreshInstall() {
        let userDefaults = UserDefaults.standard

        userDefaults.removeObject(forKey: TrialKeys.trialActivatedKey)
        userDefaults.removeObject(forKey: TrialKeys.firstLaunchDateKey)
        userDefaults.removeObject(forKey: TrialKeys.firstAppOpenForLaunchOfferKey)
        isPremiumActive = false
        hasActiveSubscription = false
        activeProductID = nil

        Task {
            await checkSubscriptionStatus()
        }

        print("SubscriptionManager: Reset to fresh install state")
    }
}

#endif
