//
//  PaywallProductID.swift
//  B2 Berufssprachkurs
//
//  Defines canonical product identifiers used by paywall and purchases.
//  Created: 04.04.26.
//

import Foundation

// MARK: - PaywallProductID

enum PaywallProductID: String, CaseIterable {
    case monthly = "hero.premium.monthly"
    case yearly = "hero.premium.yearly"
    case lifetimePromo = "hero.premium.lifetime.promo"
    case lifetimeStandard = "hero.premium.lifetime"

    /// All product IDs registered for StoreKit / RevenueCat loading (declaration order).
    static var allProductIDs: [String] {
        allCases.map(\.rawValue)
    }

    /// Subscription terms line vs one-time lifetime copy (legal + footer).
    static func usesLifetimeTerms(productIdentifier: String) -> Bool {
        productIdentifier == Self.lifetimePromo.rawValue
            || productIdentifier == Self.lifetimeStandard.rawValue
    }
}
