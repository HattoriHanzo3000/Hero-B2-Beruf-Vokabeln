//
//  LaunchConfiguration.swift
//  B2 Berufssprachkurs
//
//  DEBUG-only launch profiles driven by the HERO_LAUNCH_PROFILE scheme environment variable.
//

#if DEBUG || LOGGING
import Foundation

// MARK: - Launch Configuration

/// Seeds UserDefaults and debug overrides before managers initialize.
enum LaunchConfiguration {
    static let environmentKey = "HERO_LAUNCH_PROFILE"

    static func applyIfNeeded() {
        guard let rawProfile = ProcessInfo.processInfo.environment[environmentKey],
              !rawProfile.isEmpty,
              let profile = LaunchProfile(rawValue: rawProfile)
        else {
            return
        }

        apply(profile)
    }

    // MARK: - Private

    private enum LaunchProfile: String {
        case langDE = "lang_de"
        case langEN = "lang_en"
        case launchOfferDE = "launch_offer_de"
        case launchOfferEN = "launch_offer_en"
        case launchOfferExpiredDE = "launch_offer_expired_de"
        case launchOfferExpiredEN = "launch_offer_expired_en"
        case welcomeFresh = "welcome_fresh"
    }

    private static func apply(_ profile: LaunchProfile) {
        switch profile {
        case .langDE:
            seedPastWelcome(appLanguage: "Deutsch")
            applyProSimulation(true)
            applyExpiredLaunchOffer()
        case .langEN:
            seedPastWelcome(appLanguage: "English")
            applyProSimulation(true)
            applyExpiredLaunchOffer()
        case .launchOfferDE:
            seedPastWelcome(appLanguage: "Deutsch")
            applyFreeTier()
            applyActiveLaunchOffer()
        case .launchOfferEN:
            seedPastWelcome(appLanguage: "English")
            applyFreeTier()
            applyActiveLaunchOffer()
        case .launchOfferExpiredDE:
            seedPastWelcome(appLanguage: "Deutsch")
            applyFreeTier()
            applyExpiredLaunchOffer()
        case .launchOfferExpiredEN:
            seedPastWelcome(appLanguage: "English")
            applyFreeTier()
            applyExpiredLaunchOffer()
        case .welcomeFresh:
            resetForWelcomeVideo()
        }
    }

    private static func seedPastWelcome(appLanguage: String) {
        let defaults = UserDefaults.standard
        defaults.set(appLanguage, forKey: "appLanguage")
        defaults.set(true, forKey: "hasSeenWelcomeVideo")
    }

    private static func resetForWelcomeVideo() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "hasSeenWelcomeVideo")
        defaults.set("Deutsch", forKey: "appLanguage")
        applyProSimulation(nil)
    }

    private static func applyProSimulation(_ simulatePro: Bool?) {
        DebugOverrides.simulatePro = simulatePro
        if simulatePro == true {
            UserDefaults.standard.set(true, forKey: "lastKnownPremiumState")
        } else if simulatePro == false {
            UserDefaults.standard.set(false, forKey: "lastKnownPremiumState")
        }
    }

    private static func applyFreeTier() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: TrialKeys.trialActivatedKey)
        applyProSimulation(false)
    }

    private static func applyActiveLaunchOffer() {
        let now = Date().timeIntervalSince1970
        let defaults = UserDefaults.standard
        defaults.set(now, forKey: TrialKeys.firstAppOpenForLaunchOfferKey)
        defaults.set(now, forKey: TrialKeys.firstLaunchDateKey)
    }

    private static func applyExpiredLaunchOffer() {
        let expired = Date().addingTimeInterval(-8 * 24 * 60 * 60).timeIntervalSince1970
        let defaults = UserDefaults.standard
        defaults.set(expired, forKey: TrialKeys.firstAppOpenForLaunchOfferKey)
        defaults.set(expired, forKey: TrialKeys.firstLaunchDateKey)
    }
}
#endif
