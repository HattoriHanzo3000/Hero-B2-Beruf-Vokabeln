//
//  YourPlanView.swift
//  B2 Berufssprachkurs
//
//  Settings: current plan, tailored copy, manage subscription / paywall / restore.
//

import os
import StoreKit
import SwiftUI

struct YourPlanView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.settingsSubscriptionPreview) private var settingsSubscriptionPreview
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var showPaywall = false
    @State private var showManageSubscriptionFailed = false
    @State private var showOfferCodeRedemption = false
    @State private var lifetimeConfettiActive = false

    private var plan: YourPlanPresentation {
        YourPlanPresentation(preview: settingsSubscriptionPreview, subscriptionManager: subscriptionManager)
    }

    var body: some View {
        ZStack {
            PaywallBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    YourPlanHeroSection(
                        plan: plan,
                        statusLine: plan.effectivePlanStatusLine(subscriptionManager: subscriptionManager),
                        detailBody: plan.detailBodyText { Localizable.string($0) },
                        supplementalDateLine: plan.supplementalDateLine(
                            language: LanguageManager.shared.currentLanguage,
                            localizedString: { Localizable.string($0) }
                        )
                    )

                    YourPlanActionsSection(
                        plan: plan,
                        subscriptionManager: subscriptionManager,
                        showPaywall: $showPaywall,
                        showOfferCodeRedemption: $showOfferCodeRedemption,
                        openManageSubscriptions: openManageSubscriptions
                    )

                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.clear)

            if lifetimeConfettiActive {
                ConfettiOverlay(isActive: true)
                    .zIndex(2)
            }
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
        .alert(Localizable.string(Localizable.restorePurchase), isPresented: $subscriptionManager.showRestoreFeedbackAlert) {
            Button(Localizable.string(Localizable.ok), role: .cancel) { }
        } message: {
            Text(subscriptionManager.restoreFeedbackMessage ?? "")
        }
        .offerCodeRedemption(isPresented: $showOfferCodeRedemption) { result in
            switch result {
            case .success:
                Task {
                    await subscriptionManager.checkSubscriptionStatus()
                }
            case .failure(let error):
                AppLog.subscription.error("Offer code redemption failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        .onAppear {
            triggerConfettiIfNeeded()
        }
    }

    private func openManageSubscriptions() {
        Task { @MainActor in
            let ok = await ManageSubscriptionsPresenter.presentSystemManageSubscriptions()
            if !ok {
                showManageSubscriptionFailed = true
            }
        }
    }

    private func triggerConfettiIfNeeded() {
        guard isLifetimePlanContext else { return }
        guard !accessibilityReduceMotion else { return }
        lifetimeConfettiActive = true
        HapticManager.shared.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + ConfettiOverlay.overlayRemovalDelay) {
            lifetimeConfettiActive = false
        }
    }

    private var isLifetimePlanContext: Bool {
        if let preview = settingsSubscriptionPreview, case .lifetime = preview {
            return true
        }
        return subscriptionManager.hasLifetimeSubscription
    }
}

// MARK: - Hero

private struct YourPlanHeroSection: View {
    let plan: YourPlanPresentation
    let statusLine: String
    let detailBody: String
    let supplementalDateLine: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image("MascotLaunch")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200, maxHeight: 200)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            if plan.showsProBadgeAboveTitle {
                ProShieldBadge(
                    label: Localizable.string(Localizable.premium),
                    showShimmer: true
                )
                .frame(maxWidth: .infinity)
            }

            Text(statusLine)
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

            if plan.showsLifetimeThanks {
                Text(Localizable.string(Localizable.planDetailLifetimeThanks))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Actions

private struct YourPlanActionsSection: View {
    let plan: YourPlanPresentation
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Binding var showPaywall: Bool
    @Binding var showOfferCodeRedemption: Bool
    let openManageSubscriptions: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if plan.showsManageSubscription {
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

            if plan.showsViewProPlans {
                PaywallPrimaryButton(
                    title: Localizable.string(Localizable.viewProPlans),
                    isLoading: false,
                    isEnabled: true,
                    horizontalPadding: 8
                ) {
                    HapticManager.shared.lightImpact()
                    showPaywall = true
                }
                .padding(.top, plan.showsManageSubscription ? 20 : 10)
                .padding(.bottom, 18)
            }

            VStack(spacing: 14) {
                if plan.showsRestoreFooter {
                    PaywallFooterLinkBlock(
                        caption: Localizable.string(Localizable.paywallFooterAlreadySubscribed),
                        actionTitle: Localizable.string(Localizable.restorePurchase),
                        isActionDisabled: subscriptionManager.isLoading,
                        horizontalPadding: 8
                    ) {
                        HapticManager.shared.lightImpact()
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }
                }

                if plan.showsRedeemFooter {
                    PaywallFooterLinkBlock(
                        caption: Localizable.string(Localizable.paywallFooterGotCode),
                        actionTitle: Localizable.string(Localizable.redeem),
                        horizontalPadding: 8
                    ) {
                        HapticManager.shared.lightImpact()
                        showOfferCodeRedemption = true
                    }
                }
            }
            .padding(.top, plan.showsRestoreOrRedeemFooter ? 28 : 0)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
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
