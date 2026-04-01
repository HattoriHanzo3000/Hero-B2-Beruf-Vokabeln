//
//  YourPlanView.swift
//  B2 Berufssprachkurs
//
//  Settings: current plan, tailored copy, manage subscription / paywall / restore.
//

import SwiftUI
import StoreKit
import UIKit

struct YourPlanView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.settingsSubscriptionPreview) private var settingsSubscriptionPreview
    @State private var showPaywall = false
    @State private var showManageSubscriptionFailed = false
    @State private var showOfferCodeRedemption = false

    var body: some View {
        ZStack {
            PaywallBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image("MascotLaunch")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                    if showsProBadgeAboveTitle {
                        ProShieldBadge(
                            label: Localizable.string(Localizable.premium),
                            showShimmer: true
                        )
                        .frame(maxWidth: .infinity)
                    }

                    Text(effectivePlanStatusLine)
                        .font(.title.weight(.semibold))
                        .italic()
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(detailBody)
                        .font(.body)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .fixedSize(horizontal: false, vertical: true)

                    if let extra = supplementalDateLine {
                        Text(extra)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if showsLifetimeThanks {
                        Text(Localizable.string(Localizable.planDetailLifetimeThanks))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 0) {
                        if showsManageSubscription {
                            Button {
                                HapticManager.shared.lightImpact()
                                openManageSubscriptions()
                            } label: {
                                Text(Localizable.string(Localizable.manageSubscription))
                                    .font(.system(.footnote, design: .default).weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                        }

                        if showsViewProPlans {
                            paywallStyleViewProPlansButton()
                                .padding(.horizontal, 8)
                                .padding(.top, showsManageSubscription ? 20 : 10)
                                .padding(.bottom, 18)
                        }

                        VStack(spacing: 14) {
                            if showsRestoreFooter {
                                paywallStyleFooterBlock(
                                    caption: Localizable.string(Localizable.paywallFooterAlreadySubscribed),
                                    actionTitle: Localizable.string(Localizable.restorePurchase),
                                    isActionDisabled: subscriptionManager.isLoading
                                ) {
                                    HapticManager.shared.lightImpact()
                                    Task {
                                        await subscriptionManager.restorePurchases()
                                    }
                                }
                            }

                            if showsRedeemFooter {
                                paywallStyleFooterBlock(
                                    caption: Localizable.string(Localizable.paywallFooterGotCode),
                                    actionTitle: Localizable.string(Localizable.redeem)
                                ) {
                                    HapticManager.shared.lightImpact()
                                    showOfferCodeRedemption = true
                                }
                            }
                        }
                        .padding(.top, showsRestoreOrRedeemFooter ? 28 : 0)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.clear)
        }
        .navigationTitle(Localizable.string(Localizable.yourPlan))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert(
            Localizable.string(Localizable.manageSubscriptionFailedTitle),
            isPresented: $showManageSubscriptionFailed
        ) {
            Button(Localizable.string(Localizable.ok), role: .cancel) { }
        } message: {
            Text(Localizable.string(Localizable.manageSubscriptionFailed))
        }
        .offerCodeRedemption(isPresented: $showOfferCodeRedemption) { result in
            switch result {
            case .success:
                Task {
                    await subscriptionManager.checkSubscriptionStatus()
                }
            case .failure(let error):
                print("Offer code redemption failed: \(error.localizedDescription)")
            }
        }
    }

    /// Matches paywall primary CTA (`subscribeButtonSection`): blue gradient capsule, uppercase headline.
    private func paywallStyleViewProPlansButton() -> some View {
        Button {
            HapticManager.shared.lightImpact()
            showPaywall = true
        } label: {
            let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
            HStack {
                Spacer()
                Text(Localizable.string(Localizable.viewProPlans).uppercased())
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    .allowsTightening(true)
                Spacer()
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                shape
                    .fill(
                        LinearGradient(
                            colors: [Color("AppBlue"), Color("AppBlueThird")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.4)
                            .blendMode(.plusLighter)
                    )
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .clipShape(shape)
            .shadow(color: .black.opacity(0.16), radius: 22, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private func paywallStyleFooterBlock(
        caption: String,
        actionTitle: String,
        isActionDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 4) {
            Text(caption)
                .font(.system(.footnote, design: .default).weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Button(action: action) {
                Text(actionTitle)
                    .font(.system(.footnote, design: .default).weight(.semibold))
                    .foregroundStyle(Color("AppBlue"))
            }
            .disabled(isActionDisabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .fontDesign(.default)
    }

    // MARK: - Visibility (product rules)

    private var showsProBadgeAboveTitle: Bool {
        if settingsSubscriptionPreview != nil {
            return true
        }
        return subscriptionManager.isPremiumActive
    }

    private var showsRestoreFooter: Bool {
        if settingsSubscriptionPreview != nil {
            return false
        }
        return !subscriptionManager.isPremiumActive
    }

    private var showsRedeemFooter: Bool {
        if let preview = settingsSubscriptionPreview {
            if case .lifetime = preview { return false }
            return true
        }
        return !subscriptionManager.hasLifetimeSubscription
    }

    private var showsRestoreOrRedeemFooter: Bool {
        showsRestoreFooter || showsRedeemFooter
    }

    private var effectivePlanStatusLine: String {
        settingsSubscriptionPreview?.planStatusLine ?? subscriptionManager.localizedPlanStatusLine
    }

    private var showsLifetimeThanks: Bool {
        settingsSubscriptionPreview?.yourPlanShowsLifetimeThanks ?? subscriptionManager.hasLifetimeSubscription
    }

    private var showsManageSubscription: Bool {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanShowsManageSubscription
        }
        return subscriptionManager.hasActiveSubscription && !subscriptionManager.hasLifetimeSubscription
    }

    private var showsViewProPlans: Bool {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanShowsViewProPlans
        }
        return !subscriptionManager.hasLifetimeSubscription
    }

    private var detailBody: String {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanDetailBody
        }
        if !subscriptionManager.isPremiumActive {
            return Localizable.string(Localizable.planDetailFreeBody)
        }
        if subscriptionManager.hasLifetimeSubscription {
            return Localizable.string(Localizable.planDetailLifetimeBody)
        }
        if subscriptionManager.hasActiveSubscription {
            return Localizable.string(Localizable.planDetailSubscriptionBody)
        }
        if subscriptionManager.isLocalTrialActive {
            return Localizable.string(Localizable.planDetailTrialBody)
        }
        return Localizable.string(Localizable.planDetailSubscriptionBody)
    }

    private var supplementalDateLine: String? {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanSupplementalDateLine
        }
        // Local 3-day trial end date only when there is no store entitlement yet.
        // Otherwise lifetime / subscriptions still overlap the local trial window in UserDefaults and would show a misleading line.
        if subscriptionManager.isLocalTrialActive,
           let end = subscriptionManager.localTrialEndsAt,
           !subscriptionManager.hasLifetimeSubscription,
           !subscriptionManager.hasActiveSubscription {
            return String(format: Localizable.string(Localizable.planDetailTrialEndsFormat), formattedPlanDate(end))
        }
        if subscriptionManager.hasActiveSubscription,
           !subscriptionManager.hasLifetimeSubscription,
           let exp = subscriptionManager.premiumExpirationDate {
            return String(format: Localizable.string(Localizable.planDetailRenewsFormat), formattedPlanDate(exp))
        }
        return nil
    }

    private func formattedPlanDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        switch LanguageManager.shared.currentLanguage {
        case "Deutsch":
            formatter.locale = Locale(identifier: "de_DE")
        default:
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: date)
    }

    private func openManageSubscriptions() {
        Task { @MainActor in
            guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
                showManageSubscriptionFailed = true
                return
            }
            do {
                try await AppStore.showManageSubscriptions(in: scene)
            } catch {
                showManageSubscriptionFailed = true
            }
        }
    }
}

#Preview("Your plan — live") {
    NavigationStack {
        YourPlanView()
    }
}

#Preview("Your plan — trial") {
    NavigationStack {
        YourPlanView()
            .environment(\.settingsSubscriptionPreview, .freeTrial)
    }
}

#Preview("Your plan — monthly") {
    NavigationStack {
        YourPlanView()
            .environment(\.settingsSubscriptionPreview, .monthlySubscription)
    }
}

#Preview("Your plan — lifetime") {
    NavigationStack {
        YourPlanView()
            .environment(\.settingsSubscriptionPreview, .lifetime)
    }
}
