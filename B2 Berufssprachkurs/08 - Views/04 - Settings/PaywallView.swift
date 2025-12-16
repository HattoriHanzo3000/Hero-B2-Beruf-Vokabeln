//
//  PaywallView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProductID: String = "yearly_19.99_3d_trial"
    
    // Computed property for button text based on selected product and trial eligibility
    private var buttonText: String {
        if selectedProductID == "yearly_19.99_3d_trial" && !subscriptionManager.hasUsedTrial {
            return Localizable.string(Localizable.startFreeTrial)
        } else {
            return Localizable.string(Localizable.upgradeNow)
        }
    }
    
    // Computed property for dynamic subscription terms based on selected product
    private var dynamicSubscriptionTerms: String {
        let price: String
        
        // Get price from StoreKit product or use fallback
        if let product = subscriptionManager.products[selectedProductID] {
            // Use StoreKit product price (automatically updates if price changes)
            price = product.displayPrice
        } else {
            // Use fallback prices until StoreKit products load
            switch selectedProductID {
            case "monthly_2.99_3d_trial":
                price = "2,99€"
            case "yearly_19.99_3d_trial":
                price = "19,99€"
            case "lifetime_49.99":
                price = "49,99€"
            default:
                price = "2,99€"
            }
        }
        
        // Determine which terms template to use based on subscription type
        if selectedProductID == "lifetime_49.99" {
            // Lifetime - one-time purchase
            return String(format: Localizable.string(Localizable.subscriptionTermsLifetime), price)
        } else if selectedProductID == "yearly_19.99_3d_trial" {
            // Yearly subscription
            return String(format: Localizable.string(Localizable.subscriptionTermsYearly), price)
        } else {
            // Monthly subscription (default)
            return String(format: Localizable.string(Localizable.subscriptionTermsMonthly), price)
        }
    }
    @State private var showingError = false
    @State private var presentingLegalURL: URL? = nil
    @State private var showOfferCodeRedemption = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    benefitsSection
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
            // Load products when view appears
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.loadProducts()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = subscriptionManager.errorMessage {
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
        .onChange(of: subscriptionManager.isPremiumActive) { _, isActive in
            if isActive {
                // Subscription successful, dismiss paywall
                HapticManager.shared.success()
                dismiss()
            }
        }
        .onChange(of: subscriptionManager.purchaseState) { _, state in
            switch state {
            case .success:
                HapticManager.shared.success()
                dismiss()
            case .failed(let message):
                showingError = true
                subscriptionManager.errorMessage = message
                HapticManager.shared.error()
            default:
                break
            }
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
    
    private var subscriptionOptionsSection: some View {
        VStack(spacing: 12) {
            // Monthly subscription button
            SubscriptionOptionButton(
                title: Localizable.string(Localizable.monthly),
                explanation: Localizable.string(Localizable.monthlyExplanation),
                productID: "monthly_2.99_3d_trial",
                fallbackPrice: "2,99€",
                period: Localizable.string(Localizable.perMonth),
                isSelected: selectedProductID == "monthly_2.99_3d_trial",
                showFreeTrial: false,
                subscriptionManager: subscriptionManager,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    selectedProductID = "monthly_2.99_3d_trial"
                }
            )
            
            // Yearly subscription button
            SubscriptionOptionButton(
                title: Localizable.string(Localizable.yearly),
                explanation: Localizable.string(Localizable.yearlyExplanation),
                productID: "yearly_19.99_3d_trial",
                fallbackPrice: "19,99€",
                period: Localizable.string(Localizable.year1),
                isSelected: selectedProductID == "yearly_19.99_3d_trial",
                showFreeTrial: !subscriptionManager.hasUsedTrial,
                subscriptionManager: subscriptionManager,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    selectedProductID = "yearly_19.99_3d_trial"
                }
            )
            
            // Lifetime subscription button
            SubscriptionOptionButton(
                title: Localizable.string(Localizable.lifetime),
                explanation: Localizable.string(Localizable.lifetimeExplanation),
                productID: "lifetime_49.99",
                fallbackPrice: "49,99€",
                period: "",
                isSelected: selectedProductID == "lifetime_49.99",
                showFreeTrial: false,
                subscriptionManager: subscriptionManager,
                onSelect: {
                    HapticManager.shared.lightImpact()
                    selectedProductID = "lifetime_49.99"
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
        return !subscriptionManager.isLoading &&
        subscriptionManager.products[selectedProductID] != nil &&
        subscriptionManager.purchaseState != .purchasing &&
        subscriptionManager.purchaseState != .loading
    }
    
    // MARK: - Purchase Handling
    
    private func handlePurchase() async {
        HapticManager.shared.mediumImpact()
        
        // If Yearly is selected and trial hasn't been used, activate trial first
        if selectedProductID == "yearly_19.99_3d_trial" && !subscriptionManager.hasUsedTrial {
            subscriptionManager.activateTrial()
            // After activating trial, proceed with purchase
        }
        
        do {
            try await subscriptionManager.purchaseSubscription(productID: selectedProductID)
        } catch {
            // Error is handled by SubscriptionManager and shown via alert
            print("Purchase error: \(error.localizedDescription)")
        }
    }
    
    private func handleRestorePurchases() async {
        HapticManager.shared.lightImpact()
        await subscriptionManager.restorePurchases()
        
        if subscriptionManager.isPremiumActive {
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
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme
    let onSelect: () -> Void
    
    // Computed price text
    private var priceText: String {
        if let productID = productID, let product = subscriptionManager.products[productID] {
            if period.isEmpty {
                return product.displayPrice
            } else {
                return "\(product.displayPrice)/\(period)"
            }
        } else {
            if period.isEmpty {
                return fallbackPrice
            } else {
                return "\(fallbackPrice)/\(period)"
            }
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
                // First row: Title on left, Price on right
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(priceText)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(Color("AppGreen"))
                }
                
                // Second row: Explanation on left, Free Trial badge on right (if applicable)
                HStack(alignment: .center, spacing: 8) {
                    Text(explanation)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    
                    if showFreeTrial {
                        // Free Trial badge with smooth animation
                        FreeTrialBadge()
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
