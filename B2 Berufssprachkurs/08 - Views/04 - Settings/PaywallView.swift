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
    @State private var isMonthlySelected = true
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Crown icon
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60, weight: .semibold))
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
                    
                    // Title
                    Text(Localizable.string(Localizable.unlockFullHeroExperience))
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    // Subtitle
                    Text(Localizable.string(Localizable.proBenefitsDescription))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // Monthly subscription button
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        isMonthlySelected = true
                    }) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Localizable.string(Localizable.monthlySubscription))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(priceText)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Checkmark or circle
                            if isMonthlySelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(Color("AppGreen"))
                            } else {
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isMonthlySelected ? Color("AppGreen").opacity(0.1) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    isMonthlySelected ? Color("AppGreen") : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    Spacer(minLength: 20)
                    
                    // Terms text
                    Text(Localizable.string(Localizable.subscriptionTerms))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }
            }
            
            // Restore Purchases button (outside white box)
            Button(action: {
                Task {
                    await handleRestorePurchases()
                }
            }) {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .disabled(subscriptionManager.isLoading)
            .padding(.top, 12)
            
            // Subscribe button at bottom
            VStack(spacing: 0) {
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
                            Text(Localizable.string(Localizable.continueButton))
                                .font(.headline.weight(.semibold))
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
        .background(Color(.systemBackground))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            // Load products when view appears
            if subscriptionManager.product == nil {
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
    
    // MARK: - Computed Properties
    
    private var priceText: String {
        if let product = subscriptionManager.product {
            return "\(product.displayPrice) \(Localizable.string(Localizable.perMonth))"
        }
        return "1,99€ \(Localizable.string(Localizable.perMonth))"
    }
    
    private var isButtonEnabled: Bool {
        !subscriptionManager.isLoading &&
        subscriptionManager.product != nil &&
        subscriptionManager.purchaseState != .purchasing &&
        subscriptionManager.purchaseState != .loading
    }
    
    // MARK: - Purchase Handling
    
    private func handlePurchase() async {
        HapticManager.shared.mediumImpact()
        
        do {
            try await subscriptionManager.purchaseSubscription()
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
}

#Preview {
    PaywallView()
}
