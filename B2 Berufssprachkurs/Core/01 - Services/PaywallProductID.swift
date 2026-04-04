//
//  PaywallProductID.swift
//  B2 Berufssprachkurs
//
//  Store / RevenueCat product identifiers for the Hero paywall.
//

import Foundation

enum PaywallProductID: String, CaseIterable {
    case monthly = "hero.premium.monthly"
    case yearly = "hero.premium.yearly"

    /// Subscription terms line vs one-time lifetime copy.
    static func usesLifetimeTerms(productIdentifier: String) -> Bool {
        productIdentifier == LaunchOfferService.promoProductId
            || productIdentifier == LaunchOfferService.standardLifetimeProductId
    }
}
