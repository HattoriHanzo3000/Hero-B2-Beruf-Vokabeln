//
//  YourPlanPresentation.swift
//  B2 Berufssprachkurs
//
//  Pure plan UI state derived from preview mode and `SubscriptionManager` (testable without SwiftUI).
//

import Foundation

struct YourPlanPresentation {
    let settingsSubscriptionPreview: SettingsSubscriptionPreview?
    let isPremiumActive: Bool
    let hasLifetimeSubscription: Bool
    let hasActiveSubscription: Bool
    let isLocalTrialActive: Bool
    let localTrialEndsAt: Date?
    let premiumExpirationDate: Date?

    init(
        preview: SettingsSubscriptionPreview?,
        subscriptionManager: SubscriptionManager
    ) {
        self.settingsSubscriptionPreview = preview
        self.isPremiumActive = subscriptionManager.isPremiumActive
        self.hasLifetimeSubscription = subscriptionManager.hasLifetimeSubscription
        self.hasActiveSubscription = subscriptionManager.hasActiveSubscription
        self.isLocalTrialActive = subscriptionManager.isLocalTrialActive
        self.localTrialEndsAt = subscriptionManager.localTrialEndsAt
        self.premiumExpirationDate = subscriptionManager.premiumExpirationDate
    }

    var showsProBadgeAboveTitle: Bool {
        if settingsSubscriptionPreview != nil {
            return true
        }
        return isPremiumActive
    }

    var showsRestoreFooter: Bool {
        if settingsSubscriptionPreview != nil {
            return false
        }
        return !isPremiumActive
    }

    var showsRedeemFooter: Bool {
        if let preview = settingsSubscriptionPreview {
            if case .lifetime = preview { return false }
            return true
        }
        return !hasLifetimeSubscription
    }

    var showsRestoreOrRedeemFooter: Bool {
        showsRestoreFooter || showsRedeemFooter
    }

    func effectivePlanStatusLine(subscriptionManager: SubscriptionManager) -> String {
        settingsSubscriptionPreview?.planStatusLine ?? subscriptionManager.localizedPlanStatusLine
    }

    var showsLifetimeThanks: Bool {
        settingsSubscriptionPreview?.yourPlanShowsLifetimeThanks ?? hasLifetimeSubscription
    }

    var showsManageSubscription: Bool {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanShowsManageSubscription
        }
        return hasActiveSubscription && !hasLifetimeSubscription
    }

    var showsViewProPlans: Bool {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanShowsViewProPlans
        }
        return !hasLifetimeSubscription
    }

    func detailBodyText(localizable: (String) -> String) -> String {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanDetailBody
        }
        if !isPremiumActive {
            return localizable(Localizable.planDetailFreeBody)
        }
        if hasLifetimeSubscription {
            return localizable(Localizable.planDetailLifetimeBody)
        }
        if hasActiveSubscription {
            return localizable(Localizable.planDetailSubscriptionBody)
        }
        if isLocalTrialActive {
            return localizable(Localizable.planDetailTrialBody)
        }
        return localizable(Localizable.planDetailSubscriptionBody)
    }

    func supplementalDateLine(language: String, localizedString: (String) -> String) -> String? {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanSupplementalDateLine
        }
        if isLocalTrialActive,
           let end = localTrialEndsAt,
           !hasLifetimeSubscription,
           !hasActiveSubscription {
            let formatted = PlanDateFormatting.mediumDateString(end, language: language)
            return String(format: localizedString(Localizable.planDetailTrialEndsFormat), formatted)
        }
        if hasActiveSubscription,
           !hasLifetimeSubscription,
           let exp = premiumExpirationDate {
            let formatted = PlanDateFormatting.mediumDateString(exp, language: language)
            return String(format: localizedString(Localizable.planDetailRenewsFormat), formatted)
        }
        return nil
    }
}
