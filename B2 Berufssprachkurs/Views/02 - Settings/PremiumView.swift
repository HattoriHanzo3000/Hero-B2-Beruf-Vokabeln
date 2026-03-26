//
//  PremiumView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct PremiumView: View {
    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showPaywall = false
    
    // Determine title based on premium status
    private var titleText: String {
        if subscriptionManager.isPremiumActive {
            return Localizable.string(Localizable.enjoyFullHeroExperience)
        } else {
            return Localizable.string(Localizable.premiumUnlockTitle)
        }
    }
    
    // Title with gradient on "Hero Premium" displayed on separate line
    @ViewBuilder
    private var titleWithGradient: some View {
        let fullText = titleText
        let gradient = LinearGradient(
            colors: [
                Color("AppGreen"),
                Color("AppBlue")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Split text to find "Hero Premium" and display it on a separate line
        let heroPremiumText = "Hero Premium"
        let rowSpacing: CGFloat = 8
        
        if let range = fullText.range(of: heroPremiumText) {
            let beforeText = String(fullText[..<range.lowerBound])
            let afterText = String(fullText[range.upperBound...])
            let mainText = (beforeText + afterText).trimmingCharacters(in: .whitespaces)
            
            VStack(spacing: rowSpacing) {
                // Main text without "Hero Premium"
                if !mainText.isEmpty {
                    Text("\(mainText)")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(rowSpacing) // Match VStack spacing for consistent row spacing
                }
                
                // "Hero Premium" with gradient on separate line
                Text("\(heroPremiumText)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(gradient)
            .multilineTextAlignment(.center)
            }
        } else {
            // Fallback if "Hero Premium" not found
            Text("\(fullText)")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(rowSpacing) // Consistent spacing even in fallback
        }
    }
    
    // Determine button text based on user's subscription/trial status
    private var buttonText: String {
        if subscriptionManager.isPremiumActive {
            // Premium is active - show "Change Plan" only if not lifetime
            if subscriptionManager.hasActiveSubscription && !subscriptionManager.hasLifetimeSubscription {
                return Localizable.string(Localizable.changePlan)
            } else {
                // Lifetime or trial only - don't show button
                return ""
            }
        } else if subscriptionManager.hasUsedTrial {
            // Trial was used but cancelled - show "Upgrade to Premium"
            return Localizable.string(Localizable.upgradeToPremium)
        } else {
            // Trial not used yet - show "Unlock Premium"
            return Localizable.string(Localizable.unlockPremium)
        }
    }
    
    // Check if button should be shown
    private var shouldShowButton: Bool {
        !buttonText.isEmpty
    }
    
    // Determine button action
    private func handleButtonAction() {
        // Always show paywall
        showPaywall = true
    }
    
    var body: some View {
        ZStack {
            Color("AppGreenExtraLight")
                .ignoresSafeArea()
            
            // Playful word background
            WordWallpaperBackground(dataService: dataService)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // Crown icon and title
                        VStack(spacing: 20) {
                            // Big crown icon
                            Image(systemName: "crown.fill")
                                .font(.system(size: 80, weight: .semibold, design: .rounded))
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
                                .shadow(color: Color("AppGreen").opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            // Title - changes based on premium status with gradient on "Hero Premium"
                            titleWithGradient
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                        
                        // Comparison table
                        VStack(spacing: 14) {
                            Text(Localizable.string(Localizable.proBenefitsDescription))
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 100) // Space for fixed button
                    }
                }
                
                // Fixed Subscribe button above tab bar - only show if needed
                if shouldShowButton {
                    VStack(spacing: 0) {
                        Button(action: {
                            HapticManager.shared.mediumImpact()
                            handleButtonAction()
                        }) {
                            HStack {
                                Spacer()
                                Text(buttonText)
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                                    .foregroundColor(.white)
                                Spacer()
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
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color("AppGreen").opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .background(
                            Color("AppGreenExtraLight")
                                .ignoresSafeArea(edges: .bottom)
                        )
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    NavigationStack {
        PremiumView()
            .environmentObject(DataService())
    }
}

