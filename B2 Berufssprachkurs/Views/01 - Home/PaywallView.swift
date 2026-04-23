//
//  PaywallView.swift
//  B2 Berufssprachkurs
//
//  Premium subscription paywall with purchase, restore, and legal flows.
//  Created: 29.03.26.
//

import os
import RevenueCat
import StoreKit
import SwiftUI

// MARK: - Screen

struct PaywallView: View {
    // MARK: State & Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @ObservedObject private var revenueCatService = RevenueCatService.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var viewModel = PaywallViewModel()

    @State private var showOfferCodeRedemption = false
    /// Tracks whether a successful purchase should trigger celebration.
    @State private var expectPurchaseCelebration = false

    // MARK: Derived Data

    private var planItems: [PaywallPlanItem] {
        PaywallPlanItem.rowList(
            isLaunchOfferActive: viewModel.isLaunchOfferActive,
            countdownString: viewModel.countdownString
        )
    }

    private var primaryButtonLoading: Bool {
        subscriptionManager.purchaseState == .purchasing || subscriptionManager.purchaseState == .loading
    }

    // MARK: View Layout

    var body: some View {
        NavigationStack {
            ZStack {
                PaywallBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        PaywallPlansSection(
                            items: planItems,
                            selectedProductID: viewModel.selectedProductID,
                            subscriptionManager: subscriptionManager,
                            revenueCatService: revenueCatService,
                            onSelectProduct: { viewModel.selectProduct($0) }
                        )
                        iCloudFamilySharingLine
                        PaywallPrimaryButton(
                            title: Localizable.string(Localizable.continueButton),
                            isLoading: primaryButtonLoading,
                            isEnabled: viewModel.isPrimaryButtonEnabled
                        ) {
                            Task {
                                expectPurchaseCelebration = true
                                let ok = await viewModel.purchase()
                                if !ok {
                                    expectPurchaseCelebration = false
                                }
                            }
                        }
                        footerActionsSection
                            .padding(.top, -12)
                        PaywallLegalAgreementSection(
                            selectedProductId: viewModel.selectedProductID,
                            presentingLegalURL: bindingForLegalURL
                        )
                        .padding(.top, -12)

                        Spacer(minLength: 20)
                    }
                }
                .background(Color.clear)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .navigationBarSymbolStyle()
                    }
                    .accessibilityLabel(Localizable.string(Localizable.closePaywallA11y))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(item: legalSheetBinding) { document in
            SettingsLegalWebSheetView(url: document.url)
        }
        .task {
            viewModel.startLaunchOfferTimer()
            await viewModel.loadOfferingsAndProducts()
        }
        .onDisappear {
            viewModel.stopLaunchOfferTimer()
        }
        .alert(Localizable.string(Localizable.errorAlertTitle), isPresented: $viewModel.showingError) {
            Button(Localizable.string(Localizable.ok), role: .cancel) {}
        } message: {
            if let message = alertErrorMessage {
                Text(message)
            }
        }
        .alert(Localizable.string(Localizable.restorePurchase), isPresented: $subscriptionManager.showRestoreFeedbackAlert) {
            Button(Localizable.string(Localizable.ok), role: .cancel) {}
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
        .onChange(of: paywallPremiumState) { _, newValue in
            guard newValue.revenueCatPremium || newValue.subscriptionPremium else { return }
            if expectPurchaseCelebration {
                expectPurchaseCelebration = false
                triggerPurchaseConfettiThenDismiss()
            } else {
                HapticManager.shared.success()
                dismiss()
            }
        }
    }

    // MARK: Purchase Feedback

    /// Shows purchase celebration, then dismisses the paywall.
    private func triggerPurchaseConfettiThenDismiss() {
        if accessibilityReduceMotion {
            dismiss()
            return
        }
        PaywallWindowConfettiPresenter.show()
        HapticManager.shared.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + ConfettiOverlay.overlayRemovalDelay) {
            PaywallWindowConfettiPresenter.hide()
            dismiss()
        }
    }

    // MARK: Bindings & Helpers

    private var paywallPremiumState: PaywallPremiumState {
        PaywallPremiumState(
            revenueCatPremium: revenueCatService.isPremiumActive,
            subscriptionPremium: subscriptionManager.isPremiumActive
        )
    }

    private var alertErrorMessage: String? {
        if let m = viewModel.errorMessage { return m }
        if let m = revenueCatService.errorMessage { return m }
        if let m = subscriptionManager.errorMessage { return m }
        return nil
    }

    private var bindingForLegalURL: Binding<URL?> {
        Binding(
            get: { viewModel.presentingLegalURL },
            set: { viewModel.presentingLegalURL = $0 }
        )
    }

    private var legalSheetBinding: Binding<PaywallLegalDocument?> {
        Binding(
            get: { viewModel.presentingLegalURL.map { PaywallLegalDocument(url: $0) } },
            set: { viewModel.presentingLegalURL = $0?.url }
        )
    }

    // MARK: Components

    private var headerSection: some View {
        VStack(spacing: 12) {
            ProShieldBadge(label: Localizable.string(Localizable.premium), showShimmer: true)

            Text(Localizable.string(Localizable.paywallTitleFutureGermany))
                .font(.system(.title2, weight: .heavy).italic())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Image("Mascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 130)
                .accessibilityHidden(true)

            Text(Localizable.string(Localizable.premiumPromoSubtitle))
                .font(.system(.subheadline, design: .default).weight(.regular))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var iCloudFamilySharingLine: some View {
        Text(Localizable.string(Localizable.iCloudFamilySharing))
            .font(.system(.caption2, design: .default).weight(.medium))
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.top, 0)
            .padding(.bottom, -8)
    }

    private var footerActionsSection: some View {
        VStack(spacing: 14) {
            PaywallFooterLinkBlock(
                caption: Localizable.string(Localizable.paywallFooterAlreadySubscribed),
                actionTitle: Localizable.string(Localizable.restorePurchase),
                isActionDisabled: subscriptionManager.isLoading,
                horizontalPadding: 24
            ) {
                Task { await viewModel.restorePurchases() }
            }

            PaywallFooterLinkBlock(
                caption: Localizable.string(Localizable.paywallFooterGotCode),
                actionTitle: Localizable.string(Localizable.redeem),
                horizontalPadding: 24
            ) {
                HapticManager.shared.lightImpact()
                showOfferCodeRedemption = true
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Premium observation

private struct PaywallPremiumState: Equatable {
    var revenueCatPremium: Bool
    var subscriptionPremium: Bool
}

// MARK: - Previews

private enum PaywallPreviewSupport {
    static func applyLaunchOfferForPreview(active: Bool) {
        if active {
            LaunchOfferService.overrideFirstLaunchDateForPreview(Date())
        } else {
            LaunchOfferService.overrideFirstLaunchDateForPreview(
                Date().addingTimeInterval(-8 * 24 * 60 * 60)
            )
        }
    }
}

#Preview("Launch offer active (within 7 days)") {
    PaywallPreviewSupport.applyLaunchOfferForPreview(active: true)
    return PaywallView()
}

#Preview("Launch offer expired (after 7 days)") {
    PaywallPreviewSupport.applyLaunchOfferForPreview(active: false)
    return PaywallView()
}
