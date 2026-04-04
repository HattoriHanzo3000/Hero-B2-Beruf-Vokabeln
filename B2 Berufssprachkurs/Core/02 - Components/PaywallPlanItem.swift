//
//  PaywallPlanItem.swift
//  B2 Berufssprachkurs
//
//  Identifies each selectable row on the paywall (data-driven list).
//

import Foundation

enum PaywallPlanItem: Identifiable {
    case monthly
    case yearly(showBestValueBadge: Bool)
    case lifetimePromo(countdown: String)
    case lifetimeStandard

    var id: String {
        switch self {
        case .monthly:
            return PaywallProductID.monthly.rawValue
        case .yearly:
            return PaywallProductID.yearly.rawValue
        case .lifetimePromo:
            return LaunchOfferService.promoProductId
        case .lifetimeStandard:
            return LaunchOfferService.standardLifetimeProductId
        }
    }

    static func rowList(isLaunchOfferActive: Bool, countdownString: String) -> [PaywallPlanItem] {
        var rows: [PaywallPlanItem] = [
            .monthly,
            .yearly(showBestValueBadge: !isLaunchOfferActive)
        ]
        if isLaunchOfferActive {
            rows.append(.lifetimePromo(countdown: countdownString))
        } else {
            rows.append(.lifetimeStandard)
        }
        return rows
    }
}
