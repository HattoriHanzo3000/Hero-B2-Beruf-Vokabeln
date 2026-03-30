//
//  ProPromoSection.swift
//  B2 Berufssprachkurs
//
//  Shared gradient promo (Cockpit + Settings).
//

import SwiftUI

struct ProPromoSection: View {
    let isPremiumActive: Bool
    let hasUsedTrial: Bool
    /// When `false`, hides the trial / upgrade pill until subscription status has been resolved (avoids flashing for Pro users).
    var showFreeTierCallout: Bool = true
    /// When `true` (e.g. Settings), shows a pill to open the paywall even if the user already has Pro — for plans, restore, and subscription management.
    var showPaywallEntryWhenSubscribed: Bool = false
    let onStartFreeTrial: () -> Void

    private var wasSubscribed: Bool {
        hasUsedTrial && !isPremiumActive
    }

    private var showPaywallPill: Bool {
        if isPremiumActive {
            showPaywallEntryWhenSubscribed
        } else {
            showFreeTierCallout
        }
    }

    private var paywallPillTitle: String {
        if isPremiumActive {
            Localizable.string(Localizable.viewProPlans)
        } else if hasUsedTrial {
            Localizable.string(Localizable.upgradeToPremium)
        } else {
            Localizable.string(Localizable.startFreeTrial)
        }
    }

    private var subtitle: String {
        if isPremiumActive {
            Localizable.string(Localizable.premiumActiveSubtitle)
        } else if wasSubscribed {
            Localizable.string(Localizable.premiumFeaturesBackSubtitle)
        } else {
            Localizable.string(Localizable.premiumPromoSubtitle)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    // PRO + CTA pill (same corner radius / stroke weight as `ProShieldBadge`, filled AppBlue).
                    HStack(alignment: .top, spacing: 8) {
                        ProShieldBadge(label: "PRO", color: .white, showShimmer: true)
                        if showPaywallPill {
                            Button {
                                HapticManager.shared.lightImpact()
                                onStartFreeTrial()
                            } label: {
                                Text(paywallPillTitle)
                                .font(.system(.caption2, weight: .medium).width(.expanded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .lineLimit((!isPremiumActive && hasUsedTrial) ? 2 : 1)
                                .minimumScaleFactor(0.75)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color("AppBlue"))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Color.white, lineWidth: 0.6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .accessibilityElement(children: .combine)

                    Text(subtitle)
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image("MascotLaunch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72, alignment: .top)
                    .scaleEffect(x: -1, y: 1)
                    .accessibilityHidden(true)
            }
        }
        .padding(.top, 22)
        .padding(.bottom, 22)
        .padding(.horizontal, 18)
        // Shell corners 20pt — same continuous radius as `CockpitCard` (WOTD + Progress).
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isPremiumActive
                                ? [
                                    Color("AppGreen"),
                                    Color("AppGreen").opacity(0.94),
                                    Color("AppGreenSecond").opacity(0.92)
                                ]
                                : [
                                    Color("AppOrange"),
                                    Color("AppOrange").opacity(0.94),
                                    Color("AppOrange").opacity(0.88)
                                ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.white.opacity(0.07),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
