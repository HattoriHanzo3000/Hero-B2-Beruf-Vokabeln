//
//  PaywallPlanRow.swift
//  B2 Berufssprachkurs
//
//  Plan selection row: pricing, launch promo styling, best-value badge.
//

import RevenueCat
import StoreKit
import SwiftUI

// MARK: - Plan row

struct PaywallPlanRow: View {
    let title: String
    let explanation: String
    var secondaryExplanation: String? = nil
    let productID: String?
    var regularProductID: String? = nil
    let fallbackPrice: String
    let isSelected: Bool
    let showSeasonalOffer: Bool
    let showBestValueBadge: Bool
    let countdownText: String?
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var revenueCatService: RevenueCatService
    let onSelect: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var contentForeground: Color { isSelected ? .white : .white.opacity(0.7) }
    private var secondaryForeground: Color { isSelected ? .white.opacity(0.9) : .white.opacity(0.6) }
    private var rowOpacity: Double { isSelected ? 1.0 : 0.72 }
    private var rowSaturation: Double { isSelected ? 1.0 : 0.45 }

    private var basePriceText: String {
        getPriceString(for: productID)
    }

    private var regularPriceText: String {
        guard let id = regularProductID else { return "" }
        return getPriceString(for: id)
    }

    private func getPriceString(for id: String?) -> String {
        guard let id = id else { return "" }
        var displayPrice: String = ""

        if let offering = revenueCatService.currentOffering,
           let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == id }) {
            displayPrice = package.localizedPriceString
        } else if let product = subscriptionManager.products[id] {
            displayPrice = product.displayPrice
        }

        if displayPrice.isEmpty && !fallbackPrice.isEmpty && id == productID {
            displayPrice = fallbackPrice
        }

        if displayPrice.isEmpty { return "" }
        return displayPrice
    }

    private var slashPeriodText: String? {
        guard let productID else { return nil }
        switch productID {
        case "hero.premium.monthly":
            return "/mo"
        case "hero.premium.yearly":
            return "/yr"
        default:
            return nil
        }
    }

    private var buttonBackgroundFill: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return shape
            .fill(
                LinearGradient(
                    colors: showSeasonalOffer
                        ? [Color("AppYellow"), Color("AppYellow").opacity(0.82)]
                        : [Color("AppBlue"), Color("AppBlueThird")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.20),
                        Color.white.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(shape)
            )
    }

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(.headline, weight: .bold))
                                .foregroundStyle(contentForeground)

                            Text(explanation)
                                .font(AppFont.caption1CondensedRegular(dynamicTypeSize: dynamicTypeSize))
                                .foregroundStyle(secondaryForeground)

                            if let secondaryExplanation, !secondaryExplanation.isEmpty {
                                Text(secondaryExplanation)
                                    .font(AppFont.caption1CondensedRegular(dynamicTypeSize: dynamicTypeSize))
                                    .foregroundStyle(secondaryForeground)
                            }
                        }

                        Spacer(minLength: 8)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            if !regularPriceText.isEmpty {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(basePriceText)
                                        .font(.system(.title3, weight: .bold))
                                        .foregroundStyle(contentForeground)

                                    Text(regularPriceText)
                                        .font(.system(.caption2, weight: .medium))
                                        .strikethrough(color: secondaryForeground)
                                        .foregroundStyle(secondaryForeground)
                                }
                            } else {
                                Text(basePriceText)
                                    .font(.system(.title3, weight: .bold))
                                    .foregroundStyle(contentForeground)
                            }

                            if let slashPeriodText {
                                Text(slashPeriodText)
                                    .font(AppFont.caption1CondensedRegular(dynamicTypeSize: dynamicTypeSize))
                                    .foregroundStyle(secondaryForeground)
                            }
                        }
                    }

                    if let countdownText, !countdownText.isEmpty {
                        (
                            Text(Localizable.string(Localizable.launchOfferExpiresIn))
                                + Text(verbatim: " ")
                                + Text(countdownText).monospacedDigit()
                        )
                        .font(AppFont.caption1ExpandedRegular(dynamicTypeSize: dynamicTypeSize))
                        .foregroundStyle(secondaryForeground)
                        // Align with title text (24pt icon column + 12pt spacing); still spans to trailing edge under the price.
                        .padding(.leading, 36)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    }
                }
                .padding(16)
                .background(buttonBackgroundFill)
                .saturation(rowSaturation)
                .opacity(rowOpacity)

                if showSeasonalOffer {
                    PaywallPromoDealBadge()
                        .offset(y: -11)
                }
                if showBestValueBadge {
                    PaywallBestValueBadge()
                        .offset(y: -11)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(.easeInOut(duration: 0.25), value: isSelected)
    }
}

// MARK: - Badges

struct PaywallPromoDealBadge: View {
    @State private var isPulsing = false

    var body: some View {
        Text(Localizable.string(Localizable.launchOfferBadge))
            .font(.system(.caption2, weight: .semibold).italic())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
            .scaleEffect(isPulsing ? 1.05 : 0.97)
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct PaywallBestValueBadge: View {
    var body: some View {
        Text(Localizable.string(Localizable.paywallBestValue))
            .font(.system(.caption2, weight: .semibold).italic())
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color("AppOrange"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
    }
}
