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
    @State private var showPaywall = false
    
    // Determine button text based on user's subscription/trial status
    private var buttonText: String {
        if subscriptionManager.hasActiveSubscription {
            // User has active subscription - show "Change Plan"
            return Localizable.string(Localizable.changePlan)
        } else if subscriptionManager.hasUsedTrial {
            // Trial was used but cancelled - show "Upgrade to Premium"
            return Localizable.string(Localizable.upgradeToPremium)
        } else {
            // Trial not used yet - show "Start Free Trial"
            return Localizable.string(Localizable.startFreeTrial)
        }
    }
    
    // Determine button action
    private func handleButtonAction() {
        if subscriptionManager.hasActiveSubscription {
            // User has subscription - show paywall to change plan
            showPaywall = true
        } else if !subscriptionManager.hasUsedTrial {
            // Trial not used - activate trial
            subscriptionManager.activateTrial()
            HapticManager.shared.success()
        } else {
            // Trial used but cancelled - show paywall to subscribe
            showPaywall = true
        }
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
                            
                            // Title
                            Text(Localizable.string(Localizable.premiumUnlockTitle))
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                        
                        // Comparison table
                        PremiumComparisonTable()
                            .padding(.horizontal)
                            .padding(.bottom, 100) // Space for fixed button
                    }
                }
                
                // Fixed Subscribe button above tab bar
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
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Premium Comparison Table
private struct PremiumComparisonTable: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(alignment: .center, spacing: 0) {
                // Benefits column
                Text(Localizable.string(Localizable.benefits))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                
                Divider()
                    .frame(height: 20)
                
                // Free column
                HStack {
                    Spacer()
                    Text(Localizable.string(Localizable.free))
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .frame(width: 80)
                .padding(.vertical, 16)
                
                Divider()
                    .frame(height: 20)
                
                // Premium column
                HStack {
                    Spacer()
                    Text(Localizable.string(Localizable.premiumColumn))
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color("AppGreen"),
                                    Color("AppBlue")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Spacer()
                }
                .frame(width: 80)
                .padding(.vertical, 16)
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            // Table rows
            PremiumTableRow(
                benefit: Localizable.string(Localizable.accessToAllWords),
                freeAvailable: true,
                premiumAvailable: true
            )
            
            Divider()
                .padding(.horizontal, 16)
            
            PremiumTableRow(
                benefit: Localizable.string(Localizable.detailedProgress),
                freeAvailable: false,
                premiumAvailable: true
            )
            
            Divider()
                .padding(.horizontal, 16)
            
            PremiumTableRow(
                benefit: Localizable.string(Localizable.favoriteWords),
                freeAvailable: false,
                premiumAvailable: true
            )
            
            Divider()
                .padding(.horizontal, 16)
            
            PremiumTableRow(
                benefit: Localizable.string(Localizable.practiceModes),
                freeAvailable: false,
                premiumAvailable: true
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color("AppGreenExtraLight"))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.35),
                            .white.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.6
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Premium Table Row
private struct PremiumTableRow: View {
    let benefit: String
    let freeAvailable: Bool
    let premiumAvailable: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Benefits column
            Text(benefit)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            
            Divider()
                .frame(height: 20)
            
            // Free column
            HStack {
                Spacer()
                if freeAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(.title3, design: .rounded))
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
                } else {
                    Image(systemName: "minus")
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                Spacer()
            }
            .frame(width: 80)
            
            Divider()
                .frame(height: 20)
            
            // Premium column
            HStack {
                Spacer()
                if premiumAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(.title3, design: .rounded))
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
                } else {
                    Image(systemName: "minus")
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                Spacer()
            }
            .frame(width: 80)
        }
    }
}

#Preview {
    NavigationStack {
        PremiumView()
            .environmentObject(DataService())
    }
}

