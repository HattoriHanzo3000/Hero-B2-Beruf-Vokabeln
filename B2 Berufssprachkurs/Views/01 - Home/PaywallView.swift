//
//  PaywallView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import RevenueCat
import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var revenueCatService = RevenueCatService.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var viewModel = PaywallViewModel()

    @State private var showOfferCodeRedemption = false

    private var planItems: [PaywallPlanItem] {
        PaywallPlanItem.rowList(
            isLaunchOfferActive: viewModel.isLaunchOfferActive,
            countdownString: viewModel.countdownString
        )
    }

    private var primaryButtonLoading: Bool {
        subscriptionManager.purchaseState == .purchasing || subscriptionManager.purchaseState == .loading
    }

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
                            Task { await viewModel.purchase() }
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
        .onChange(of: paywallPremiumState) { _, newValue in
            if newValue.revenueCatPremium || newValue.subscriptionPremium {
                HapticManager.shared.success()
                dismiss()
            }
        }
    }

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

    private var headerSection: some View {
        VStack(spacing: 12) {
            ProShieldBadge(label: Localizable.string(Localizable.premium), showShimmer: true)

            Text(Localizable.string(Localizable.paywallTitleFutureGermany))
                .font(.system(.title2, weight: .heavy).italic())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Image("MascotLaunch")
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
            VStack(spacing: 4) {
                Text(Localizable.string(Localizable.paywallFooterAlreadySubscribed))
                    .font(.system(.footnote, design: .default).weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                Button(action: {
                    Task { await viewModel.restorePurchases() }
                }) {
                    Text(Localizable.string(Localizable.restorePurchase))
                        .font(.system(.footnote, design: .default).weight(.semibold))
                        .foregroundColor(Color("AppBlue"))
                }
                .disabled(subscriptionManager.isLoading)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 4) {
                Text(Localizable.string(Localizable.paywallFooterGotCode))
                    .font(.system(.footnote, design: .default).weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                Button(action: {
                    HapticManager.shared.lightImpact()
                    showOfferCodeRedemption = true
                }) {
                    Text(Localizable.string(Localizable.redeem))
                        .font(.system(.footnote, design: .default).weight(.semibold))
                        .foregroundColor(Color("AppBlue"))
                }
            }
            .padding(.horizontal, 24)
        }
        .fontDesign(.default)
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
