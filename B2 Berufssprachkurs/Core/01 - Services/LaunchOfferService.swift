//
//  LaunchOfferService.swift
//  B2 Berufssprachkurs
//
//  3-day lifetime promo window (launch offer) based on first app launch.
//

import Foundation

enum LaunchOfferService {
    // RevenueCat package identifier values (matched against `Package.identifier`)
    static let promoPackageIdentifier = "$rc_lifetime_promo"

    // App Store Connect product identifiers (matched against `StoreProduct.productIdentifier`)
    static let standardLifetimeProductId = "hero.premium.lifetime"

    // Your app already stores this key for trial timing in `SubscriptionManager`.
    private static let firstLaunchDateKey = "firstLaunchDate"

    // 3 days (72 hours)
    private static let launchWindowSeconds: TimeInterval = 72 * 60 * 60

    /// Date of first app launch. Nil if never recorded.
    static var firstLaunchDate: Date? {
        UserDefaults.standard.object(forKey: firstLaunchDateKey) as? Date
    }

    /// True if current time is within 72 hours of first app launch.
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
}

