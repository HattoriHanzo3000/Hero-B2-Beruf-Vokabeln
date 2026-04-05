//
//  SubscriptionManager+Debug.swift
//  B2 Berufssprachkurs
//

import Foundation

extension SubscriptionManager {
    func deactivatePremiumForTesting() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: TrialKeys.trialActivatedKey)
        userDefaults.removeObject(forKey: TrialKeys.firstLaunchDateKey)
        userDefaults.removeObject(forKey: TrialKeys.firstAppOpenForLaunchOfferKey)

        isPremiumActive = false

        Task {
            await checkSubscriptionStatus()
        }

        print("SubscriptionManager: Premium deactivated for testing")
    }

    /// Debug helper to force-enable premium state via trial activation.
    func activatePremiumForTesting() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(Date().timeIntervalSince1970, forKey: TrialKeys.firstLaunchDateKey)
        userDefaults.set(true, forKey: TrialKeys.trialActivatedKey)

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
