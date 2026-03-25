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
        var price: String = ""
        
        // Try to get price from RevenueCat package first
        if let offering = revenueCatService.currentOffering,
           let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == selectedProductID }) {
            // Use RevenueCat package price
            price = package.localizedPriceString
        } else if let product = subscriptionManager.products[selectedProductID] {
            // Fallback to StoreKit product
            price = product.displayPrice
        }
        
        // Determine which terms template to use based on subscription type
        if selectedProductID == "hero.premium.lifetime" || selectedProductID == "hero.premium.lifetime.promo" {
            // Lifetime - one-time purchase
            return String(format: Localizable.string(Localizable.subscriptionTermsLifetime), price)
        } else if selectedProductID == "hero.premium.quarterly" {
            return String(format: Localizable.string(Localizable.subscriptionTermsQuarterly), price)
        } else {
            // Monthly subscription (default)
            return String(format: Localizable.string(Localizable.subscriptionTermsMonthly), price)
        }
    }
    @State private var showingError = false
    @State private var presentingLegalURL: URL? = nil
    @State private var showOfferCodeRedemption = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Vertical gradient background using your app colors
            LinearGradient(
                colors: [
                    Color("AppGreen"),
                    Color("AppBlue")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    benefitsSection
                    seasonalPromotionalBanner
                    subscriptionOptionsSection
                    
                    // Main CTA
                    subscribeButtonSection
                    
                    // Benefits block again, matching the "after continue" layout
                    benefitsSection
                    
                    // Restore purchases + redeem code
                    footerActionsSection
                    
                    // Legal boilerplate + bottom legal row
                    termsSection
                    legalActionsRow
                    
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
            // Premium shield badge
            HStack(spacing: 8) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color("AppGreen"),
                                Color("AppBlue")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text(Localizable.string(Localizable.premium))
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(.white.opacity(0.95))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(Color.white.opacity(0.12)))
            .overlay(Capsule().stroke(Color.white.opacity(0.28), lineWidth: 1))

            // Title with gradient
            Text(Localizable.string(Localizable.heroPremiumSubscription))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color("AppGreen"),
                            Color("AppBlue")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Subtitle copy (separate from the title)
            Text(Localizable.string(Localizable.premiumPromoSubtitle))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Mascot (reuses existing app assets)
            Image(mascotImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 130)
                .accessibilityHidden(true)
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
    
    private var benefitsBlockText: String {
        let parts = [
            Localizable.string(Localizable.accessToAllWords),
            Localizable.string(Localizable.detailedProgress),
            Localizable.string(Localizable.favoriteWords),
            Localizable.string(Localizable.practiceModes),
            Localizable.string(Localizable.wordOfTheDayCustomization),
            Localizable.string(Localizable.shareExportWords)
        ]
        // One consolidated block of text (no checkmarks).
        return parts.joined(separator: "\n")
    }
    
    private var benefitsSection: some View {
        VStack(spacing: 12) {
            Text(benefitsBlockText)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 24)
        }
        .padding(.top, 8)
    }
    
    private var seasonalPromotionalBanner: some View {
        // Banner removed - no promotional offers
        EmptyView()
    }
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: 12) {
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
                title: Localizable.string(Localizable.premium3Months),
                explanation: Localizable.string(Localizable.quarterlyExplanation),
                productID: "hero.premium.quarterly",
                fallbackPrice: "",
                period: Localizable.string(Localizable.months3),
                isSelected: selectedProductID == "hero.premium.quarterly",
                showFreeTrial: false,
                showSeasonalOffer: false,
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
                    productID: LaunchOfferService.promoProductId,
                    regularProductID: LaunchOfferService.standardLifetimeProductId,
                    fallbackPrice: "",
                    period: "",
                    isSelected: selectedProductID == LaunchOfferService.promoProductId,
                    showFreeTrial: false,
                    showSeasonalOffer: false,
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
                    productID: LaunchOfferService.standardLifetimeProductId,
                    fallbackPrice: "",
                    period: "",
                    isSelected: selectedProductID == LaunchOfferService.standardLifetimeProductId,
                    showFreeTrial: false,
                    showSeasonalOffer: false,
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
            
            // iCloud Family sharing text
            Text(Localizable.string(Localizable.iCloudFamilySharing))
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 12)
        }
    }
    
    private var footerActionsSection: some View {
        VStack(spacing: 16) {
            // Already Upgraded section
            VStack(spacing: 8) {
                Text(Localizable.string(Localizable.alreadyUpgraded))
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    Task {
                        await handleRestorePurchases()
                    }
                }) {
                    Text(Localizable.string(Localizable.restorePurchase))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color("AppGreen"))
                }
                .disabled(subscriptionManager.isLoading)
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
    
    private var subscribeButtonSection: some View {
        VStack(spacing: 0) {
            // Thin border line at top of footer
            Divider()
                .background(Color(.separator))
            
            Button(action: {
                Task {
                    await handlePurchase()
                }
            }) {
                HStack {
                    if subscriptionManager.purchaseState == .purchasing || subscriptionManager.purchaseState == .loading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Spacer()
                        Text(buttonText)
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            Color("AppGreen"),
                            Color("AppBlue")
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .opacity(isButtonEnabled ? 1.0 : 0.6)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color("AppGreen").opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .disabled(!isButtonEnabled)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
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
    let productID: String?
    var regularProductID: String? = nil // Optional original product for strikethrough
    let fallbackPrice: String
    let period: String
    let isSelected: Bool
    let showFreeTrial: Bool
    let showSeasonalOffer: Bool
    let countdownText: String?
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var revenueCatService: RevenueCatService
    @Environment(\.colorScheme) private var colorScheme
    let onSelect: () -> Void
    
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
        
        if period.isEmpty {
            return displayPrice
        } else {
            return "\(displayPrice)/\(period)"
        }
    }
    
    // Check if this is the yearly subscription button
    private var isYearlyButton: Bool {
        // Repurpose the "highlight" style for the limited lifetime promo.
        // (The full countdown UI will be implemented in a later step.)
        return productID == "hero.premium.lifetime.promo"
    }
    
    // Christmas gradient for yearly button
    private var christmasGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.85, green: 0.15, blue: 0.15), // Deep red
                Color(red: 0.15, green: 0.65, blue: 0.15),  // Deep green
                Color(red: 0.85, green: 0.15, blue: 0.15)   // Deep red again
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Yellow color for price
    private var yellowColor: Color {
        Color.yellow
    }
    
    // Button background color that's lighter in dark mode
    private var buttonBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(.systemGray5)
        } else {
            return Color(.systemGray6)
        }
    }
    
    // Background fill for button
    @ViewBuilder
    private var buttonBackgroundFill: some View {
        if isYearlyButton {
            // Christmas gradient for yearly button
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(christmasGradient)
                .opacity(isSelected ? 1.0 : 0.15)
        } else {
            // Regular background for other buttons
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? Color("AppGreen").opacity(0.1) : buttonBackgroundColor)
        }
    }
    
    // Border stroke for button
    @ViewBuilder
    private var buttonBorder: some View {
        if isYearlyButton {
            // Yellow border for yearly button when selected
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isSelected ? yellowColor : Color.clear,
                    lineWidth: 2
                )
        } else {
            // Regular border for other buttons
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isSelected ? Color("AppGreen") : Color.clear,
                    lineWidth: 2
                )
        }
    }
    
    // Price color
    private var priceColor: Color {
        if isYearlyButton && isSelected {
            return yellowColor
        } else {
            return Color("AppGreen")
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // First row: Title on left, Price on right
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(isYearlyButton && isSelected ? .white : .primary)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if !regularPriceText.isEmpty {
                            Text(regularPriceText)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(isSelected ? .white.opacity(0.6) : .secondary)
                                .strikethrough()
                        }
                        
                        Text(basePriceText)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(priceColor)
                    }
                }
                
                // Second row: Explanation on left, Badges on right
                HStack(alignment: .center, spacing: 8) {
                    Text(explanation)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(isYearlyButton && isSelected ? .white.opacity(0.9) : .secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 6) {
                        if showSeasonalOffer {
                            SeasonalOfferBadge()
                        }
                        
                        if showFreeTrial {
                            FreeTrialBadge()
                        }
                    }
                }
                
                // Third row: Holiday sale info (only for yearly button)
                if let countdownText, !countdownText.isEmpty {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(isYearlyButton && isSelected ? .white.opacity(0.9) : Color("AppGreen"))
                        Text(Localizable.string(Localizable.launchOfferExpiresIn))
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundColor(isYearlyButton && isSelected ? .white.opacity(0.9) : .secondary)
                        Text(countdownText)
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .monospacedDigit()
                            .foregroundColor(isYearlyButton && isSelected ? .white : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }
            }
            .padding(16)
            .background(buttonBackgroundFill)
            .overlay(buttonBorder)
            .shadow(
                color: isYearlyButton && isSelected ? yellowColor.opacity(0.3) : Color.clear,
                radius: isYearlyButton && isSelected ? 8 : 0
            )
        }
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

// MARK: - Benefit Checklist Item
private struct BenefitChecklistItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color("AppGreen"),
                            Color("AppBlue")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PaywallView()
}
