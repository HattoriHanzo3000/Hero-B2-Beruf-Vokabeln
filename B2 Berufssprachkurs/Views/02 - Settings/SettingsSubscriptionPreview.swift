//
//  SettingsSubscriptionPreview.swift
//  B2 Berufssprachkurs
//
//  Subscription UI snapshots for SwiftUI Previews (Settings + Your Plan).
//

import SwiftUI

enum SettingsSubscriptionPreview: Hashable, Sendable {
    case freeTrial
    case monthlySubscription
    case lifetime
}

extension SettingsSubscriptionPreview {
    var planStatusLine: String {
        switch self {
        case .freeTrial:
            Localizable.string(Localizable.planStatusTrial)
        case .monthlySubscription:
            Localizable.string(Localizable.planStatusMonthly)
        case .lifetime:
            Localizable.string(Localizable.planStatusLifetime)
        }
    }

    var proPromoIsPremium: Bool { true }

    var proPromoHasUsedTrial: Bool { true }

    /// Avoid the “Checking…” placeholder in canvas.
    var proPromoShowFreeTierCallout: Bool { true }

    var yourPlanDetailBody: String {
        switch self {
        case .freeTrial:
            Localizable.string(Localizable.planDetailTrialBody)
        case .monthlySubscription:
            Localizable.string(Localizable.planDetailSubscriptionBody)
        case .lifetime:
            Localizable.string(Localizable.planDetailLifetimeBody)
        }
    }

    var yourPlanSupplementalDateLine: String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        switch self {
        case .freeTrial:
            let end = Date().addingTimeInterval(2 * 24 * 3600)
            return String(format: Localizable.string(Localizable.planDetailTrialEndsFormat), formatter.string(from: end))
        case .monthlySubscription:
            let renew = Date().addingTimeInterval(30 * 24 * 3600)
            return String(format: Localizable.string(Localizable.planDetailRenewsFormat), formatter.string(from: renew))
        case .lifetime:
            return nil
        }
    }

    var yourPlanShowsManageSubscription: Bool {
        self == .monthlySubscription
    }

    var yourPlanShowsViewProPlans: Bool {
        self != .lifetime
    }

    var yourPlanShowsLifetimeThanks: Bool {
        self == .lifetime
    }
}

struct SettingsSubscriptionPreviewKey: EnvironmentKey {
    static let defaultValue: SettingsSubscriptionPreview? = nil
}

extension EnvironmentValues {
    var settingsSubscriptionPreview: SettingsSubscriptionPreview? {
        get { self[SettingsSubscriptionPreviewKey.self] }
        set { self[SettingsSubscriptionPreviewKey.self] = newValue }
    }
}
