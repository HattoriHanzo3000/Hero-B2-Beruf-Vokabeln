//
//  PaywallView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import StoreKit
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var revenueCatService = RevenueCatService.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared // Keep for trial logic
    @State private var selectedProductID: String = "hero.premium.yearly"
    @State private var selectedPackage: Package?
    @State private var isLoadingPackages = false
    
    // Computed property for button text based on selected product and trial eligibility
    private var buttonText: String {
        if selectedProductID == "hero.premium.yearly" && !subscriptionManager.hasUsedTrial {
            return Localizable.string(Localizable.startFreeTrial)
        } else {
            return Localizable.string(Localizable.upgradeNow)
        }
    }
    
    // Helper function to check if we're in the promotional period
    private var isSeasonalOfferActive: Bool {
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        
        // Promotional offer is active until January 15, 2026
        return now <= cutoffDate
    }
    
    // Helper function to get yearly fallback price based on seasonal pricing
    private var yearlyFallbackPrice: String {
        if isSeasonalOfferActive {
            return "9,99€"
        } else {
            return "14,99€"
        }
    }
    
    // Computed property for dynamic subscription terms based on selected product
    private var dynamicSubscriptionTerms: String {
        var price: String = ""
        var renewalPrice: String? = nil
        
        // Try to get price from RevenueCat package first
        if let offering = revenueCatService.currentOffering,
           let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == selectedProductID }) {
            // Use RevenueCat package price
            price = package.localizedPriceString
            
            // For yearly subscription during promotional period, set renewal price
            if selectedProductID == "hero.premium.yearly" && isSeasonalOfferActive {
                renewalPrice = "14,99€" // Base renewal price
            }
        } else if let product = subscriptionManager.products[selectedProductID] {
            // Fallback to StoreKit product
            // For yearly subscription during promotional period
            if selectedProductID == "hero.premium.yearly" && isSeasonalOfferActive {
                // Get promotional price (first year) from the promotional offer
                if let subscription = product.subscription {
                    var promoPriceFound = false
                    for offer in subscription.promotionalOffers {
                        if offer.id == "christmas.sale" {
                            price = offer.displayPrice
                            promoPriceFound = true
                            break
                        }
                    }
                    if !promoPriceFound {
                        price = product.displayPrice
                    }
                } else {
                    price = product.displayPrice
                }
                
                // Get the base/regular price for renewal (after first year)
                renewalPrice = product.displayPrice
            } else {
                // Use StoreKit product price (automatically updates if price changes)
                price = product.displayPrice
                renewalPrice = nil
            }
        } else {
            // Use fallback prices until products/packages load
            switch selectedProductID {
            case "hero.premium.monthly":
                price = "1,99€"
                renewalPrice = nil
            case "hero.premium.yearly":
                price = yearlyFallbackPrice
                // During promotional period, renewal will be at regular price
                renewalPrice = isSeasonalOfferActive ? "14,99€" : nil
            case "hero.premium.lifetime":
                price = "29,99€"
                renewalPrice = nil
            default:
                price = "1,99€"
                renewalPrice = nil
            }
        }
        
        // Determine which terms template to use based on subscription type
        if selectedProductID == "hero.premium.lifetime" {
            // Lifetime - one-time purchase
            return String(format: Localizable.string(Localizable.subscriptionTermsLifetime), price)
        } else if selectedProductID == "hero.premium.yearly" {
            // Yearly subscription - check if we need to show promotional pricing info
            if let renewalPrice = renewalPrice, isSeasonalOfferActive {
                // Show terms with both promotional and renewal prices
                return String(format: Localizable.string(Localizable.subscriptionTermsYearlyPromotional), price, renewalPrice)
            } else {
                // Regular yearly subscription terms
                return String(format: Localizable.string(Localizable.subscriptionTermsYearly), price)
            }
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
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    benefitsSection
                    seasonalPromotionalBanner
                    subscriptionOptionsSection
                    termsSection
                    footerActionsSection
                    Spacer(minLength: 20)
                }
            }
            subscribeButtonSection
        }
        .background(Color(.systemBackground))
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
            
            // Set selected package based on selected product ID
            updateSelectedPackage()
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
        VStack(spacing: 0) {
            // Crown icon
            Image(systemName: "crown.fill")
                .font(.system(size: 60, weight: .semibold, design: .rounded))
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
                .shadow(color: Color("AppGreen").opacity(0.3), radius: 15, x: 0, y: 8)
                .padding(.top, 32)
            
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
        }
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BenefitChecklistItem(
                text: Localizable.string(Localizable.accessToAllWords)
            )
            BenefitChecklistItem(
                text: Localizable.string(Localizable.detailedProgress)
            )
            BenefitChecklistItem(
                text: Localizable.string(Localizable.favoriteWords)
            )
            BenefitChecklistItem(
                text: Localizable.string(Localizable.practiceModes)
            )
            BenefitChecklistItem(
                text: Localizable.string(Localizable.wordOfTheDayCustomization)
            )
            BenefitChecklistItem(
                text: Localizable.string(Localizable.shareExportWords)
            )
        }
        .padding(.horizontal, 32)
        .padding(.top, 8)
    }
    
    private var seasonalPromotionalBanner: some View {
        Group {
            if isSeasonalOfferActive {
                HolidaySeasonalBanner(subscriptionManager: subscriptionManager)
            }
        }
    }
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: 12) {
            // Monthly subscription button
            SubscriptionOptionButton(
                title: Localizable.string(Localizable.monthly),
                explanation: Localizable.string(Localizable.monthlyExplanation),
                productID: "hero.premium.monthly",
                fallbackPrice: "1,99€",
                period: Localizable.string(Localizable.perMonth),
                isSelected: selectedProductID == "hero.premium.monthly",
                showFreeTrial: false,
                showSeasonalOffer: false,
                subscriptionManager: subscriptionManager,
                revenueCatService: revenueCatService,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    selectedProductID = "hero.premium.monthly"
                }
            )
            
            // Yearly subscription button
            SubscriptionOptionButton(
                title: Localizable.string(Localizable.yearly),
                explanation: Localizable.string(Localizable.yearlyExplanation),
                productID: "hero.premium.yearly",
                fallbackPrice: yearlyFallbackPrice,
                period: Localizable.string(Localizable.year1),
                isSelected: selectedProductID == "hero.premium.yearly",
                showFreeTrial: !subscriptionManager.hasUsedTrial,
                showSeasonalOffer: false,
                subscriptionManager: subscriptionManager,
                revenueCatService: revenueCatService,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    selectedProductID = "hero.premium.yearly"
                }
            )
            
            // Lifetime subscription button
            SubscriptionOptionButton(
                title: Localizable.string(Localizable.lifetime),
                explanation: Localizable.string(Localizable.lifetimeExplanation),
                productID: "hero.premium.lifetime",
                fallbackPrice: "29,99€",
                period: "",
                isSelected: selectedProductID == "hero.premium.lifetime",
                showFreeTrial: false,
                showSeasonalOffer: false,
                subscriptionManager: subscriptionManager,
                revenueCatService: revenueCatService,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    selectedProductID = "hero.premium.lifetime"
                }
            )
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
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Functional links to Terms of Use and Privacy Policy
                HStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        presentingLegalURL = URL(string: "https://www.gizatech.de/hero-b2-beruf/terms-of-use")
                    }) {
                        Text(Localizable.string(Localizable.termsOfUse))
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color("AppGreen"))
                    }
                    
                    Text("•")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        presentingLegalURL = URL(string: "https://www.gizatech.de/hero-b2-beruf/privacy-policy")
                    }) {
                        Text(Localizable.string(Localizable.privacyPolicy))
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color("AppGreen"))
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
            
            // iCloud Family sharing text
            Text(Localizable.string(Localizable.iCloudFamilySharing))
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
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
                    .foregroundColor(.secondary)
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
            
            // Redeem Offer Code section
            VStack(spacing: 8) {
                Text(Localizable.string(Localizable.gotACode))
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    HapticManager.shared.lightImpact()
                    showOfferCodeRedemption = true
                }) {
                    Text(Localizable.string(Localizable.redeem))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color("AppGreen"))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
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
            .background(Color(.systemBackground))
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
                    if selectedProductID == "hero.premium.yearly" && !subscriptionManager.hasUsedTrial {
                        subscriptionManager.activateTrial()
                    }
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
    let fallbackPrice: String
    let period: String
    let isSelected: Bool
    let showFreeTrial: Bool
    let showSeasonalOffer: Bool
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var revenueCatService: RevenueCatService
    @Environment(\.colorScheme) private var colorScheme
    let onSelect: () -> Void
    
    // Helper to check if seasonal offer is active (for yearly subscription)
    private var isSeasonalOfferActive: Bool {
        let calendar = Calendar.current
        let now = Date()
        let cutoffDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        return now <= cutoffDate
    }
    
    // Check if price is promotional
    private var isPromotionalPrice: Bool {
        guard let productID = productID else { return false }
        return productID == "hero.premium.yearly" && isSeasonalOfferActive
    }
    
    // Get the promotional price string
    private var promotionalPriceText: String {
        var displayPrice: String = ""
        
        // Try RevenueCat package first
        if let productID = productID,
           let offering = revenueCatService.currentOffering,
           let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == productID }) {
            displayPrice = package.localizedPriceString
        } else if let productID = productID, let product = subscriptionManager.products[productID] {
            // Fallback to StoreKit product
            // For yearly subscription during promotional period, try to get promotional price
            if productID == "hero.premium.yearly" && isSeasonalOfferActive {
                // Try to get promotional price from the offer
                if let subscription = product.subscription {
                    for offer in subscription.promotionalOffers {
                        if offer.id == "christmas.sale" {
                            displayPrice = offer.displayPrice
                            break
                        }
                    }
                    // If promotional offer not found, use product price
                    if displayPrice.isEmpty {
                        displayPrice = product.displayPrice
                    }
                } else {
                    displayPrice = product.displayPrice
                }
            } else {
                displayPrice = product.displayPrice
            }
        } else {
            displayPrice = fallbackPrice
        }
        
        if period.isEmpty {
            return displayPrice
        } else {
            return "\(displayPrice)/\(period)"
        }
    }
    
    // Get the regular price string (for strikethrough)
    private var regularPriceText: String {
        guard let productID = productID else { return "" }
        
        // Try RevenueCat package first
        if let offering = revenueCatService.currentOffering,
           let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == productID }) {
            let basePrice = package.localizedPriceString
            if period.isEmpty {
                return basePrice
            } else {
                return "\(basePrice)/\(period)"
            }
        } else if let product = subscriptionManager.products[productID] {
            // Fallback to StoreKit product
            let basePrice = product.displayPrice
            if period.isEmpty {
                return basePrice
            } else {
                return "\(basePrice)/\(period)"
            }
        } else {
            // Use fallback regular price
            let regularPrice = productID == "hero.premium.yearly" ? "14,99€" : fallbackPrice
            if period.isEmpty {
                return regularPrice
            } else {
                return "\(regularPrice)/\(period)"
            }
        }
    }
    
    // Get the display price string (for non-promotional)
    private var basePriceText: String {
        var displayPrice: String = ""
        
        // Try RevenueCat package first
        if let productID = productID,
           let offering = revenueCatService.currentOffering,
           let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == productID }) {
            displayPrice = package.localizedPriceString
        } else if let productID = productID, let product = subscriptionManager.products[productID] {
            // Fallback to StoreKit product
            displayPrice = product.displayPrice
        } else {
            displayPrice = fallbackPrice
        }
        
        if period.isEmpty {
            return displayPrice
        } else {
            return "\(displayPrice)/\(period)"
        }
    }
    
    // Price display view with icon and SALE text for promotional
    @ViewBuilder
    private var priceDisplayView: some View {
        if isPromotionalPrice {
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    // Gift box icon - same font as SALE
                    Image(systemName: "gift.fill")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.red)
                    
                    // SALE text
                    Text(Localizable.string(Localizable.sale))
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.red)
                    
                    // Promotional price in red
                    Text(promotionalPriceText)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.red)
                }
                
                // Regular price with strikethrough
                Text(regularPriceText)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                    .strikethrough()
            }
        } else {
            Text(basePriceText)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(Color("AppGreen"))
        }
    }
    
    // Button background color that's lighter in dark mode
    private var buttonBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(.systemGray5)
        } else {
            return Color(.systemGray6)
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                if isPromotionalPrice {
                    // First row: Title on left, Sale price on right
                    HStack {
                        Text(title)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Sale price with icon and SALE text
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.red)
                            
                            Text(Localizable.string(Localizable.sale))
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(.red)
                            
                            Text(promotionalPriceText)
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Second row: Explanation on left, Regular price (strikethrough) on right
                    HStack {
                        Text(explanation)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        // Regular price with strikethrough
                        Text(regularPriceText)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                            .strikethrough()
                    }
                    
                    // Third row: Free Trial badge aligned right
                    if showFreeTrial {
                        HStack {
                            Spacer()
                            FreeTrialBadge()
                        }
                    }
                } else {
                    // Non-promotional layout (original)
                    // First row: Title on left, Price on right
                    HStack {
                        Text(title)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(basePriceText)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Color("AppGreen"))
                    }
                    
                    // Second row: Explanation on left, Badges on right
                    HStack(alignment: .center, spacing: 8) {
                        Text(explanation)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
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
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color("AppGreen").opacity(0.1) : buttonBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? Color("AppGreen") : Color.clear,
                        lineWidth: 2
                    )
            )
        }
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
private struct FreeTrialBadge: View {
    @State private var isAnimating = false
    
    var body: some View {
        Text(Localizable.string(Localizable.freeTrial))
            .font(.system(.caption2, design: .rounded).weight(.bold))
            .foregroundColor(Color("AppOrange"))
            .textCase(.uppercase)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color("AppOrange").opacity(isAnimating ? 0.35 : 0.15))
            )
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .shadow(color: Color("AppOrange").opacity(isAnimating ? 0.4 : 0.2), radius: isAnimating ? 8 : 4, x: 0, y: 2)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
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
