//
//  LaunchOfferService.swift
//  B2 Berufssprachkurs
//
//  7-day lifetime promo window (launch offer) based on first app launch.
//

import Foundation

enum LaunchOfferService {
    // App Store Connect product identifier values (matched against `StoreProduct.productIdentifier`)
    static let promoProductId = "hero.premium.lifetime.promo"

    // RevenueCat package identifier values (matched against `Package.identifier`) - kept for reference.
    static let promoPackageIdentifier = "$rc_lifetime_promo"

    // App Store Connect product identifiers (matched against `StoreProduct.productIdentifier`)
    static let standardLifetimeProductId = "hero.premium.lifetime"

    // Your app already stores this key for trial timing in `SubscriptionManager`.
    private static let firstLaunchDateKey = "firstLaunchDate"

    // 7 days (168 hours)
    private static let launchWindowSeconds: TimeInterval = 7 * 24 * 60 * 60

    /// Date of first app launch. Nil if never recorded.
    static var firstLaunchDate: Date? {
        let raw = UserDefaults.standard.object(forKey: firstLaunchDateKey)
        if let date = raw as? Date {
            return date
        }
        if let timestamp = raw as? TimeInterval {
            return Date(timeIntervalSince1970: timestamp)
        }
        return nil
    }

    /// True if current time is within 7 days of first app launch.
    static var isLaunchOfferActive: Bool {
        remainingSeconds > 0
    }

    /// Seconds remaining until the launch offer expires. 0 if expired.
    static var remainingSeconds: TimeInterval {
        guard let launch = firstLaunchDate else { return 0 }
        let elapsed = Date().timeIntervalSince(launch)
        return max(0, launchWindowSeconds - elapsed)
    }

    /// Seconds remaining formatted as e.g. "2d 04h 15m 10s".
    static func formattedCountdown(from remaining: TimeInterval) -> String {
        let totalSeconds = max(0, Int(remaining))
        let d = totalSeconds / 86400
        let h = (totalSeconds % 86400) / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return String(format: "%dd %02dh %02dm %02ds", d, h, m, s)
    }

    /// Convenience countdown string for current state.
    static var countdownString: String {
        formattedCountdown(from: remainingSeconds)
    }

    /// For SwiftUI previews / tests: control the stored first-launch date (same key as runtime).
    static func overrideFirstLaunchDateForPreview(_ date: Date?) {
        if let date {
            UserDefaults.standard.set(date, forKey: firstLaunchDateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: firstLaunchDateKey)
        }
    }
}

