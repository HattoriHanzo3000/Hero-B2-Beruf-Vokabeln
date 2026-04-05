//
//  PaywallPlansSection.swift
//  B2 Berufssprachkurs
//
//  Renders `PaywallPlanRow` for each `PaywallPlanItem`.
//

import RevenueCat
import SwiftUI

struct PaywallPlansSection: View {
    let items: [PaywallPlanItem]
    let selectedProductID: String
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var revenueCatService: RevenueCatService
    let onSelectProduct: (String) -> Void

    var body: some View {
        VStack(spacing: 18) {
            ForEach(items) { item in
                planRow(for: item)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func planRow(for item: PaywallPlanItem) -> some View {
        switch item {
        case .monthly:
            PaywallPlanRow(
                title: Localizable.string(Localizable.monthly),
                explanation: Localizable.string(Localizable.monthlyExplanation),
                productID: PaywallProductID.monthly.rawValue,
                fallbackPrice: "",
                isSelected: selectedProductID == PaywallProductID.monthly.rawValue,
                showSeasonalOffer: false,
                showBestValueBadge: false,
                countdownText: nil,
                subscriptionManager: subscriptionManager,
                revenueCatService: revenueCatService,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    onSelectProduct(PaywallProductID.monthly.rawValue)
                }
            )
        case .yearly(let showBestValue):
            PaywallPlanRow(
                title: Localizable.string(Localizable.yearly),
                explanation: Localizable.string(Localizable.yearlyExplanation),
                productID: PaywallProductID.yearly.rawValue,
                fallbackPrice: "",
                isSelected: selectedProductID == PaywallProductID.yearly.rawValue,
                showSeasonalOffer: false,
                showBestValueBadge: showBestValue,
                countdownText: nil,
                subscriptionManager: subscriptionManager,
                revenueCatService: revenueCatService,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    onSelectProduct(PaywallProductID.yearly.rawValue)
                }
            )
        case .lifetimePromo(let countdown):
            PaywallPlanRow(
                title: Localizable.string(Localizable.lifetime),
                explanation: Localizable.string(Localizable.lifetimeExplanation),
                secondaryExplanation: Localizable.string(Localizable.lifetimeExplanationLine2),
                productID: PaywallProductID.lifetimePromo.rawValue,
                regularProductID: PaywallProductID.lifetimeStandard.rawValue,
                fallbackPrice: "",
                isSelected: selectedProductID == PaywallProductID.lifetimePromo.rawValue,
                showSeasonalOffer: true,
                showBestValueBadge: false,
                countdownText: countdown,
                subscriptionManager: subscriptionManager,
                revenueCatService: revenueCatService,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    onSelectProduct(PaywallProductID.lifetimePromo.rawValue)
                }
            )
        case .lifetimeStandard:
            PaywallPlanRow(
                title: Localizable.string(Localizable.lifetime),
                explanation: Localizable.string(Localizable.lifetimeExplanation),
                secondaryExplanation: Localizable.string(Localizable.lifetimeExplanationLine2),
                productID: PaywallProductID.lifetimeStandard.rawValue,
                fallbackPrice: "",
                isSelected: selectedProductID == PaywallProductID.lifetimeStandard.rawValue,
                showSeasonalOffer: false,
                showBestValueBadge: false,
                countdownText: nil,
                subscriptionManager: subscriptionManager,
                revenueCatService: revenueCatService,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    onSelectProduct(PaywallProductID.lifetimeStandard.rawValue)
                }
            )
        }
    }
}
