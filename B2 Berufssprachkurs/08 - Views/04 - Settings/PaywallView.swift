//
//  PaywallView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isMonthlySelected = true
    
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
                        .padding(.top, 8)
                    
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
                                
                                Text("1,99€ \(Localizable.string(Localizable.perMonth))")
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
            
            // Subscribe button at bottom
            VStack(spacing: 0) {
                Button(action: {
                    HapticManager.shared.mediumImpact()
                    // TODO: Implement subscription purchase
                }) {
                    HStack {
                        Spacer()
                        Text(Localizable.string(Localizable.continueButton))
                            .font(.headline.weight(.semibold))
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
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PaywallView()
}
