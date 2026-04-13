//
//  SubscriptionManager+LocalTrial.swift
//  B2 Berufssprachkurs
//
//  Local trial support and trial-state computations.
//  Created: 06.04.26.
//

import Foundation

// MARK: - TrialKeys

enum TrialKeys {
    static let trialPeriodDays: TimeInterval = 3 * 24 * 60 * 60
    static let firstLaunchDateKey = "firstLaunchDate"
    /// First app open for the 7-day launch offer; not overwritten when the user starts the in-app trial.
    static let firstAppOpenForLaunchOfferKey = "firstAppOpenDateForLaunchOffer"
    static let trialActivatedKey = "trialActivated"
}

extension SubscriptionManager {
    /// True while the in-app 3-day trial is active (no store subscription required).
    var isLocalTrialActive: Bool {
        isTrialActive()
    }

    /// End date of the in-app trial, when ``isLocalTrialActive`` is `true`.
    var localTrialEndsAt: Date? {
        let userDefaults = UserDefaults.standard
        guard userDefaults.bool(forKey: TrialKeys.trialActivatedKey),
              let ts = userDefaults.object(forKey: TrialKeys.firstLaunchDateKey) as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: ts).addingTimeInterval(TrialKeys.trialPeriodDays)
    }

    var hasUsedTrial: Bool {
        UserDefaults.standard.bool(forKey: TrialKeys.trialActivatedKey)
    }

    func activateTrial() {
        let userDefaults = UserDefaults.standard

        guard !userDefaults.bool(forKey: TrialKeys.trialActivatedKey) else {
            return
        }

        let now = Date()
        userDefaults.set(now.timeIntervalSince1970, forKey: TrialKeys.firstLaunchDateKey)
        userDefaults.set(true, forKey: TrialKeys.trialActivatedKey)

        print("SubscriptionManager: 3-day free trial activated")

        isPremiumActive = true
    }

    func initializeTrialIfNeeded() {
        let userDefaults = UserDefaults.standard

        if userDefaults.bool(forKey: TrialKeys.trialActivatedKey) {
            updatePremiumStatusFromTrial()
            return
        }

        if userDefaults.object(forKey: TrialKeys.firstLaunchDateKey) == nil {
            let now = Date()
            let ts = now.timeIntervalSince1970
            userDefaults.set(ts, forKey: TrialKeys.firstLaunchDateKey)
            userDefaults.set(ts, forKey: TrialKeys.firstAppOpenForLaunchOfferKey)
        } else if userDefaults.object(forKey: TrialKeys.firstAppOpenForLaunchOfferKey) == nil,
                  !userDefaults.bool(forKey: TrialKeys.trialActivatedKey),
                  let installTs = userDefaults.object(forKey: TrialKeys.firstLaunchDateKey) as? TimeInterval {
            userDefaults.set(installTs, forKey: TrialKeys.firstAppOpenForLaunchOfferKey)
        }
    }

    func isTrialActive() -> Bool {
        let userDefaults = UserDefaults.standard

        guard userDefaults.bool(forKey: TrialKeys.trialActivatedKey) else {
            return false
        }

        guard let firstLaunchTimestamp = userDefaults.object(forKey: TrialKeys.firstLaunchDateKey) as? TimeInterval else {
            return false
        }

        let firstLaunchDate = Date(timeIntervalSince1970: firstLaunchTimestamp)
        let trialEndDate = firstLaunchDate.addingTimeInterval(TrialKeys.trialPeriodDays)
        return Date() < trialEndDate
    }

    func updatePremiumStatusFromTrial() {
        let trialActive = isTrialActive()

        if trialActive {
            Task {
                await checkSubscriptionStatus()
            }
            if !isPremiumActive {
                isPremiumActive = true
            }
        } else {
            Task {
                await checkSubscriptionStatus()
            }
        }
    }
}
