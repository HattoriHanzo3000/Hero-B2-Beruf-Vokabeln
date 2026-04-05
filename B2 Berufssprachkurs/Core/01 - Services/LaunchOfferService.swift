//
//  LaunchOfferService.swift
//  B2 Berufssprachkurs
//
//  7-day lifetime promo window (launch offer) based on first app open.
//
//  Anchor date is stored separately from ``SubscriptionManager``’s `firstLaunchDate`, which is
//  overwritten when the user starts the in-app trial (trial end uses that timestamp).
//

import Foundation

enum LaunchOfferService {
    /// RevenueCat package identifier (matched against `Package.identifier`); see RevenueCat dashboard.
    static let promoPackageIdentifier = "$rc_lifetime_promo"

    /// Written once at first open (and migrated on upgrade); never overwritten by trial activation.
    /// See ``SubscriptionManager`` for trial timing on `firstLaunchDate`.
    private static let firstAppOpenForLaunchOfferKey = "firstAppOpenDateForLaunchOffer"

    // 7 days (168 hours)
    private static let launchWindowSeconds: TimeInterval = 7 * 24 * 60 * 60

    /// Date of first app open used for the launch-offer window. Nil if never recorded.
    static var firstAppOpenDate: Date? {
        let raw = UserDefaults.standard.object(forKey: firstAppOpenForLaunchOfferKey)
        if let date = raw as? Date {
            return date
        }
        if let timestamp = raw as? TimeInterval {
            return Date(timeIntervalSince1970: timestamp)
        }
        return nil
    }

    /// True if current time is within 7 days of first app open.
    static var isLaunchOfferActive: Bool {
        remainingSeconds > 0
    }

    /// Seconds remaining until the launch offer expires. 0 if expired.
    static var remainingSeconds: TimeInterval {
        guard let anchor = firstAppOpenDate else { return 0 }
        let elapsed = Date().timeIntervalSince(anchor)
        return max(0, launchWindowSeconds - elapsed)
    }

    /// Seconds remaining as a single-line string with fixed unit suffixes (`d`, `h`, lowercase `m`, `s`).
    static func formattedCountdown(from remaining: TimeInterval) -> String {
        let totalSeconds = max(0, Int(remaining))
        let d = totalSeconds / 86_400
        let h = (totalSeconds % 86_400) / 3_600
        let m = (totalSeconds % 3_600) / 60
        let s = totalSeconds % 60
        return String(format: "%dd %02dh %02dm %02ds", d, h, m, s)
    }

    /// Convenience countdown string for current state.
    static var countdownString: String {
        formattedCountdown(from: remainingSeconds)
    }

    /// For SwiftUI previews / tests: control the stored anchor date (same key as runtime).
    static func overrideFirstLaunchDateForPreview(_ date: Date?) {
        if let date {
            UserDefaults.standard.set(date, forKey: firstAppOpenForLaunchOfferKey)
        } else {
            UserDefaults.standard.removeObject(forKey: firstAppOpenForLaunchOfferKey)
        }
    }
}
