//
//  PaywallView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import StoreKit
import RevenueCat
import Combine
import UIKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var revenueCatService = RevenueCatService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProductID: String = "hero.premium.quarterly"
    @State private var selectedPackage: Package?
    @State private var isLoadingPackages = false
    
    @State private var isLaunchOfferActive = LaunchOfferService.isLaunchOfferActive
    @State private var countdownString = LaunchOfferService.countdownString
    
    private var buttonText: String {
        Localizable.string(Localizable.continueButton)
    }
    
    private var dynamicSubscriptionTerms: String {
        if selectedProductID == "hero.premium.lifetime" || selectedProductID == "hero.premium.lifetime.promo" {
            return Localizable.string(Localizable.subscriptionTermsLifetime)
        } else if selectedProductID == "hero.premium.quarterly" {
            return Localizable.string(Localizable.subscriptionTermsQuarterly)
        } else {
            return Localizable.string(Localizable.subscriptionTermsMonthly)
        }
    }
    @State private var showingError = false
    @State private var presentingLegalURL: URL? = nil
    @State private var showOfferCodeRedemption = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            PaywallBackground()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    subscriptionOptionsSection
                    iCloudFamilySharingLine
                    subscribeButtonSection
                    footerActionsSection
                        .padding(.top, -12)
                    termsSection
                        .padding(.top, -12)
                    legalActionsRow
                        .padding(.top, -12)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color.clear)
        }
        // MARK: Presentation & side effects
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(item: Binding(
            get: { presentingLegalURL.map { LegalDocument(url: $0) } },
            set: { presentingLegalURL = $0?.url }
        )) { document in
            SettingsLegalWebSheetView(url: document.url)
        }
        .task {
            // Load RevenueCat offerings when view appears
            if revenueCatService.currentOffering == nil {
                isLoadingPackages = true
                await revenueCatService.loadOfferings()
                isLoadingPackages = false
            }
            
            // Also load products for fallback
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.loadProducts()
            }
            
            // Default selection depends on the 7-day lifetime promo window
            isLaunchOfferActive = LaunchOfferService.isLaunchOfferActive
            selectedProductID = isLaunchOfferActive ? LaunchOfferService.promoProductId : "hero.premium.quarterly"
            countdownString = isLaunchOfferActive ? LaunchOfferService.countdownString : ""
            
            // Set selected package based on selected product ID
            updateSelectedPackage()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            let activeNow = LaunchOfferService.isLaunchOfferActive
            if activeNow != isLaunchOfferActive {
                isLaunchOfferActive = activeNow
                if !activeNow && selectedProductID == LaunchOfferService.promoProductId {
                    // Promo expired while paywall is open; fall back to quarterly (Hero default).
                    selectedProductID = "hero.premium.quarterly"
                }
            }
            countdownString = activeNow ? LaunchOfferService.countdownString : ""
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = errorMessage ?? revenueCatService.errorMessage ?? subscriptionManager.errorMessage {
                Text(errorMessage)
            }
        }
        .offerCodeRedemption(isPresented: $showOfferCodeRedemption) { result in
            // Offer code redemption completed
            switch result {
            case .success:
                // Refresh subscription status to check if user redeemed a code
                Task {
                    await subscriptionManager.checkSubscriptionStatus()
                }
            case .failure(let error):
                // Handle error if needed
                print("Offer code redemption failed: \(error.localizedDescription)")
            }
        }
        .onChange(of: revenueCatService.isPremiumActive) { _, isActive in
            if isActive {
                // Subscription successful, dismiss paywall
                HapticManager.shared.success()
                dismiss()
            }
        }
        .onChange(of: subscriptionManager.isPremiumActive) { _, isActive in
            if isActive {
                // Subscription successful, dismiss paywall
                HapticManager.shared.success()
                dismiss()
            }
        }
        .onChange(of: selectedProductID) { _, _ in
            updateSelectedPackage()
        }
    }
    
    // MARK: - Scroll content (top to bottom)
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Premium badge (copied design)
            PremiumShieldBadge(label: Localizable.string(Localizable.premium), showShimmer: true)

            // Title (SF Pro, italic, white)
            Text(Localizable.string(Localizable.paywallTitleFutureGermany))
                .font(.system(.title2, weight: .heavy).italic())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Mascot (reuses existing app assets)
            Image(mascotImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 130)
                .accessibilityHidden(true)

            // Subtitle copy (separate from the title)
            Text(Localizable.string(Localizable.premiumPromoSubtitle))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    private var mascotImageName: String {
        if colorScheme == .dark, UIImage(named: "MascotDark") != nil {
            return "MascotDark"
        }
        return "Mascot"
    }
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: 18) {
            // Monthly subscription button
            PaywallPlanRow(
                title: Localizable.string(Localizable.monthly),
                explanation: Localizable.string(Localizable.monthlyExplanation),
                productID: "hero.premium.monthly",
                fallbackPrice: "",
                isSelected: selectedProductID == "hero.premium.monthly",
                showSeasonalOffer: false,
                showBestValueBadge: false,
                countdownText: nil,
                subscriptionManager: subscriptionManager,
                revenueCatService: revenueCatService,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    selectedProductID = "hero.premium.monthly"
                }
            )
            
            // Quarterly subscription button
            PaywallPlanRow(
                title: Localizable.string(Localizable.months3),
                explanation: Localizable.string(Localizable.quarterlyExplanation),
                productID: "hero.premium.quarterly",
                fallbackPrice: "",
                isSelected: selectedProductID == "hero.premium.quarterly",
                showSeasonalOffer: false,
                showBestValueBadge: !isLaunchOfferActive,
                countdownText: nil,
                subscriptionManager: subscriptionManager,
                revenueCatService: revenueCatService,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    selectedProductID = "hero.premium.quarterly"
                }
            )
            
            // Lifetime subscription button
            if isLaunchOfferActive {
                PaywallPlanRow(
                    title: Localizable.string(Localizable.lifetime),
                    explanation: Localizable.string(Localizable.lifetimeExplanation),
                    secondaryExplanation: Localizable.string(Localizable.lifetimeExplanationLine2),
                    productID: LaunchOfferService.promoProductId,
                    regularProductID: LaunchOfferService.standardLifetimeProductId,
                    fallbackPrice: "",
                    isSelected: selectedProductID == LaunchOfferService.promoProductId,
                    showSeasonalOffer: true,
                    showBestValueBadge: false,
                    countdownText: countdownString,
                    subscriptionManager: subscriptionManager,
                    revenueCatService: revenueCatService,
                    onSelect: {
                        HapticManager.shared.lightImpact()
                        selectedProductID = LaunchOfferService.promoProductId
                    }
                )
            } else {
                PaywallPlanRow(
                    title: Localizable.string(Localizable.lifetime),
                    explanation: Localizable.string(Localizable.lifetimeExplanation),
                    secondaryExplanation: Localizable.string(Localizable.lifetimeExplanationLine2),
                    productID: LaunchOfferService.standardLifetimeProductId,
                    fallbackPrice: "",
                    isSelected: selectedProductID == LaunchOfferService.standardLifetimeProductId,
                    showSeasonalOffer: false,
                    showBestValueBadge: false,
                    countdownText: nil,
                    subscriptionManager: subscriptionManager,
                    revenueCatService: revenueCatService,
                    onSelect: {
                        HapticManager.shared.lightImpact()
                        selectedProductID = LaunchOfferService.standardLifetimeProductId
                    }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    private var iCloudFamilySharingLine: some View {
        Text(Localizable.string(Localizable.iCloudFamilySharing))
            .font(.system(.caption2, design: .rounded).weight(.medium))
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.top, 0)
            .padding(.bottom, -8)
    }
    
    private var subscribeButtonSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                Task {
                    await handlePurchase()
                }
            }) {
                let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

                HStack {
                    if subscriptionManager.purchaseState == .purchasing || subscriptionManager.purchaseState == .loading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Spacer()
                        Text(buttonText.uppercased())
                            .font(.system(.headline, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.85)
                            .allowsTightening(true)
                        Spacer()
                    }
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
                        .opacity(isButtonEnabled ? 1.0 : 0.75)
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
                .shadow(color: .black.opacity(isButtonEnabled ? 0.16 : 0.08), radius: 22, x: 0, y: 10)
                .scaleEffect(isButtonEnabled ? 1 : 0.98)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isButtonEnabled)
            }
            .disabled(!isButtonEnabled)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 18)
            .background(Color.clear)
        }
    }
    
    private var footerActionsSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                Task {
                    await handleRestorePurchases()
                }
            }) {
                Text(Localizable.string(Localizable.restorePurchase))
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .disabled(subscriptionManager.isLoading)
            .padding(.horizontal, 24)
            .padding(.top, 0)
        }
        .padding(.top, 4)
    }
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text(dynamicSubscriptionTerms)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
    }
    
    private var legalActionsRow: some View {
        HStack(spacing: 8) {
            Button(action: {
                HapticManager.shared.lightImpact()
                presentingLegalURL = URL(string: "https://www.gizatech.de/hero-b2-beruf/terms-of-use")
            }) {
                Text(Localizable.string(Localizable.termsOfUse))
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Text("·")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            
            Button(action: {
                HapticManager.shared.lightImpact()
                presentingLegalURL = URL(string: "https://www.gizatech.de/hero-b2-beruf/privacy-policy")
            }) {
                Text(Localizable.string(Localizable.privacyPolicy))
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            Text("·")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            
            Button(action: {
                HapticManager.shared.lightImpact()
                showOfferCodeRedemption = true
            }) {
                Text(Localizable.string(Localizable.redeem))
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .buttonStyle(.plain)
    }
    
    // MARK: - Computed Properties
    
    private var isButtonEnabled: Bool {
        // Enable if we have a package from RevenueCat or a product from StoreKit
        let hasPackage = selectedPackage != nil
        let hasProduct = subscriptionManager.products[selectedProductID] != nil
        let isNotLoading = !isLoadingPackages && !subscriptionManager.isLoading
        let isNotPurchasing = subscriptionManager.purchaseState != .purchasing && subscriptionManager.purchaseState != .loading
        
        return isNotLoading && (hasPackage || hasProduct) && isNotPurchasing
    }
    
    // MARK: - Purchase Handling
    
    private func handlePurchase() async {
        HapticManager.shared.mediumImpact()
        
        // Try to purchase through RevenueCat first
        if let package = selectedPackage {
            do {
                let (_, userCancelled) = try await revenueCatService.purchase(package: package)
                if !userCancelled {
                    // Purchase successful - activate trial if applicable
                    // No free-trial activation here; premium is granted via RevenueCat.
                }
            } catch RevenueCatError.userCancelled {
                // User cancelled - no error needed
            } catch {
                // Fallback to SubscriptionManager if RevenueCat fails
                do {
                    try await subscriptionManager.purchaseSubscription(productID: selectedProductID)
                } catch {
                    showingError = true
                    errorMessage = error.localizedDescription
                    print("Purchase error: \(error.localizedDescription)")
                }
            }
        } else {
            // Fallback to SubscriptionManager if no package found
            do {
                try await subscriptionManager.purchaseSubscription(productID: selectedProductID)
            } catch {
                showingError = true
                errorMessage = error.localizedDescription
                print("Purchase error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Updates the selected package based on selected product ID
    private func updateSelectedPackage() {
        guard let offering = revenueCatService.currentOffering else {
            selectedPackage = nil
            return
        }
        
        selectedPackage = offering.availablePackages.first { $0.storeProduct.productIdentifier == selectedProductID }
    }
    
    private func handleRestorePurchases() async {
        HapticManager.shared.lightImpact()
        
        // Try RevenueCat restore first
        do {
            try await revenueCatService.restorePurchases()
            if revenueCatService.isPremiumActive {
                showingError = false
                return
            }
        } catch {
            print("RevenueCat restore failed: \(error.localizedDescription)")
        }
        
        // Fallback to SubscriptionManager
        await subscriptionManager.restorePurchases()
        
        if subscriptionManager.isPremiumActive || revenueCatService.isPremiumActive {
            // Restore successful - dismiss will be handled by onChange
            showingError = false
        } else {
            // Show error if no subscription found
            showingError = true
        }
    }
    
    // Legal document identifier for sheet presentation
    struct LegalDocument: Identifiable {
        let url: URL
        var id: URL { url }
    }
}

#Preview("Launch offer active (within 7 days)") {
    // Simulate first launch happening "now" so the 7-day promo is active.
    UserDefaults.standard.set(Date(), forKey: "firstLaunchDate")
    return PaywallView()
}

#Preview("Launch offer expired (after 7 days)") {
    // Simulate first launch 8 days ago so the promo is expired.
    UserDefaults.standard.set(Date().addingTimeInterval(-8 * 24 * 60 * 60), forKey: "firstLaunchDate")
    return PaywallView()
}
