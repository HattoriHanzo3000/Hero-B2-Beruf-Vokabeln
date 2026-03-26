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

private extension Font {
    static var paywallSubtitleCondensed: Font {
        Font(UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize, weight: .regular, width: .condensed))
    }

    static var paywallSubtitleExpanded: Font {
        Font(UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize, weight: .regular, width: .expanded))
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var revenueCatService = RevenueCatService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared // Keep for trial logic
    @State private var selectedProductID: String = "hero.premium.quarterly"
    @State private var selectedPackage: Package?
    @State private var isLoadingPackages = false
    
    @State private var isLaunchOfferActive = LaunchOfferService.isLaunchOfferActive
    @State private var countdownString = LaunchOfferService.countdownString
    
    // Computed property for button text based on selected product and trial eligibility
    private var buttonText: String {
        Localizable.string(Localizable.continueButton)
    }
    
    // Computed property for dynamic subscription terms based on selected product
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
            // Hero-style dark-to-light green background with liquid-glass highlight.
            LinearGradient(
                colors: [
                    Color("AppGreen").opacity(0.99),
                    Color("AppGreen").opacity(0.65),
                    Color("AppGreenSecond").opacity(0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
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
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    seasonalPromotionalBanner
                    subscriptionOptionsSection
                    
                    Text(Localizable.string(Localizable.iCloudFamilySharing))
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 0)
                        .padding(.bottom, -8)
                    
                    // Main CTA
                    subscribeButtonSection
                    
                    // Restore purchases + redeem code
                    footerActionsSection
                        .padding(.top, -12)
                    
                    // Legal boilerplate + bottom legal row
                    termsSection
                        .padding(.top, -12)
                    legalActionsRow
                        .padding(.top, -12)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color.clear)
        }
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
            
            // Default selection depends on the 3-day lifetime promo window
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
                    // Promo expired while paywall is open; fall back to standard lifetime.
                    selectedProductID = LaunchOfferService.standardLifetimeProductId
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
    
    // MARK: - View Components
    
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
    
    private var seasonalPromotionalBanner: some View {
        // Banner removed - no promotional offers
        EmptyView()
    }
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: 18) {
            // Monthly subscription button
            SubscriptionOptionButton(
                title: Localizable.string(Localizable.monthly),
                explanation: Localizable.string(Localizable.monthlyExplanation),
                productID: "hero.premium.monthly",
                fallbackPrice: "",
                period: Localizable.string(Localizable.perMonth),
                isSelected: selectedProductID == "hero.premium.monthly",
                showFreeTrial: false,
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
            SubscriptionOptionButton(
                title: Localizable.string(Localizable.months3),
                explanation: Localizable.string(Localizable.quarterlyExplanation),
                productID: "hero.premium.quarterly",
                fallbackPrice: "",
                period: Localizable.string(Localizable.months3),
                isSelected: selectedProductID == "hero.premium.quarterly",
                showFreeTrial: false,
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
                SubscriptionOptionButton(
                    title: Localizable.string(Localizable.lifetime),
                    explanation: Localizable.string(Localizable.lifetimeExplanation),
                    secondaryExplanation: Localizable.string(Localizable.lifetimeExplanationLine2),
                    productID: LaunchOfferService.promoProductId,
                    regularProductID: LaunchOfferService.standardLifetimeProductId,
                    fallbackPrice: "",
                    period: "",
                    isSelected: selectedProductID == LaunchOfferService.promoProductId,
                    showFreeTrial: false,
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
                SubscriptionOptionButton(
                    title: Localizable.string(Localizable.lifetime),
                    explanation: Localizable.string(Localizable.lifetimeExplanation),
                    secondaryExplanation: Localizable.string(Localizable.lifetimeExplanationLine2),
                    productID: LaunchOfferService.standardLifetimeProductId,
                    fallbackPrice: "",
                    period: "",
                    isSelected: selectedProductID == LaunchOfferService.standardLifetimeProductId,
                    showFreeTrial: false,
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
    
    private var termsSection: some View {
        VStack(spacing: 12) {
            // Terms text
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

// MARK: - Subscription Option Button
private struct SubscriptionOptionButton: View {
    let title: String
    let explanation: String
    var secondaryExplanation: String? = nil
    let productID: String?
    var regularProductID: String? = nil // Optional original product for strikethrough
    let fallbackPrice: String
    let period: String
    let isSelected: Bool
    let showFreeTrial: Bool
    let showSeasonalOffer: Bool
    let showBestValueBadge: Bool
    let countdownText: String?
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var revenueCatService: RevenueCatService
    let onSelect: () -> Void

    private var contentForeground: Color { isSelected ? .white : .white.opacity(0.7) }
    private var secondaryForeground: Color { isSelected ? .white.opacity(0.9) : .white.opacity(0.6) }
    
    // Get the display price string from RevenueCat or StoreKit
    private var basePriceText: String {
        getPriceString(for: productID)
    }
    
    // Get the regular (old) price string for strikethrough
    private var regularPriceText: String {
        guard let id = regularProductID else { return "" }
        return getPriceString(for: id)
    }
    
    private func getPriceString(for id: String?) -> String {
        guard let id = id else { return "" }
        var displayPrice: String = ""
        
        // Try RevenueCat package first
        if let offering = revenueCatService.currentOffering,
           let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == id }) {
            displayPrice = package.localizedPriceString
        } else if let product = subscriptionManager.products[id] {
            // Fallback to StoreKit product
            displayPrice = product.displayPrice
        }
        
        // Only use fallback if we have no price and fallback is provided
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
        case "hero.premium.quarterly":
            return "/3mo"
        default:
            return nil
        }
    }
    
    // Background fill for button
    private var buttonBackgroundFill: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return shape
            .fill(
                LinearGradient(
                    colors: showSeasonalOffer
                    ? [Color("AppOrange"), Color("AppOrange").opacity(0.82)]
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
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.7))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(.headline, weight: .bold))
                            .foregroundStyle(contentForeground)

                        Text(explanation)
                            .font(.paywallSubtitleCondensed)
                            .foregroundStyle(secondaryForeground)

                        if let secondaryExplanation, !secondaryExplanation.isEmpty {
                            Text(secondaryExplanation)
                                .font(.paywallSubtitleCondensed)
                                .foregroundStyle(secondaryForeground)
                        }

                        if let countdownText, !countdownText.isEmpty {
                            HStack(spacing: 4) {
                                Text(Localizable.string(Localizable.launchOfferExpiresIn))
                                    .font(.paywallSubtitleExpanded)
                                Text(countdownText)
                                    .font(.paywallSubtitleExpanded)
                                    .monospacedDigit()
                            }
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
                                .font(.paywallSubtitleCondensed)
                                .foregroundStyle(secondaryForeground)
                        }
                    }
                }
                .padding(16)
                .background(buttonBackgroundFill)

                if showSeasonalOffer {
                    PromoDealBadge()
                        .offset(y: -11)
                }
                if showBestValueBadge {
                    BestValueBadge()
                        .offset(y: -11)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(.easeInOut(duration: 0.25), value: isSelected)
    }
}

private struct PromoDealBadge: View {
    var body: some View {
        Text(Localizable.string(Localizable.launchOfferBadge))
            .font(.system(.caption2, weight: .semibold).italic())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
    }
}

private struct BestValueBadge: View {
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

// MARK: - Holiday Sale Row
private struct HolidaySaleRow: View {
    let isSelected: Bool
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Animated gift icon
            Image(systemName: "gift.fill")
                .font(.system(.title, design: .rounded).weight(.semibold))
                .foregroundColor(isSelected ? yellowColor : Color("AppGreen"))
                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            VStack(alignment: .leading, spacing: 2) {
                // Title - matches yearly title color
                Text(Localizable.string(Localizable.holidaySeasonSale))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Description without price - matches explanation text color
                Text(Localizable.string(Localizable.holidaySeasonSaleDescriptionNoPrice))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.top, 4)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
    
    private var yellowColor: Color {
        Color.yellow
    }
}

// MARK: - Seasonal Offer Badge
private struct SeasonalOfferBadge: View {
    @State private var isAnimating = false
    
    var body: some View {
        Text("Limited Time")
            .font(.system(.caption2, design: .rounded).weight(.bold))
            .foregroundColor(Color("AppBlue"))
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color("AppBlue").opacity(isAnimating ? 0.3 : 0.15))
            )
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .shadow(color: Color("AppBlue").opacity(isAnimating ? 0.3 : 0.15), radius: isAnimating ? 6 : 3, x: 0, y: 2)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2.5)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Free Trial Badge with Animation
// MARK: - Free Trial Badge with Animation & Shimmer
private struct FreeTrialBadge: View {
    @State private var isAnimating = false
    @State private var shimmerOffset: CGFloat = -100
    
    var body: some View {
        Text(Localizable.string(Localizable.freeTrial))
            .font(.system(.caption2, design: .rounded).weight(.bold))
            .foregroundColor(.white) // White text for better contrast on gradient
            .textCase(.uppercase)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    // Base Golden Gradient
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.9, blue: 0.0), // Bright Yellow
                                    Color(red: 0.85, green: 0.65, blue: 0.13), // Golden
                                    Color(red: 1.0, green: 0.8, blue: 0.0)  // Yellow-Gold
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Shimmer Overlay
                    GeometryReader { geometry in
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.4), // The "shine"
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 50) // Width of the shine
                            .offset(x: shimmerOffset)
                            .onAppear {
                                startShimmer(width: geometry.size.width)
                            }
                    }
                    .clipShape(Capsule()) // Keep shimmer inside the badge
                }
            )
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .shadow(color: Color.yellow.opacity(isAnimating ? 0.5 : 0.3), radius: isAnimating ? 8 : 4, x: 0, y: 2)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
    
    private func startShimmer(width: CGFloat) {
        Task {
            while true {
                shimmerOffset = -100
                // Wait for a few seconds between shimmers
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 second pause
                
                withAnimation(.linear(duration: 2.0)) { // 2 second sweep
                    shimmerOffset = width + 50
                }
                
                // Wait for the animation to finish before resetting
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
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
