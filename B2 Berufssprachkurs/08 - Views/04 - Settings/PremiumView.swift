//
//  PremiumView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct PremiumView: View {
    var body: some View {
        ZStack {
            Color("AppGreenExtraLight")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Crown icon and title
                    VStack(spacing: 20) {
                        // Big crown icon
                        Image(systemName: "crown.fill")
                            .font(.system(size: 80, weight: .semibold))
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
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                    
                    // Comparison table
                    PremiumComparisonTable()
                        .padding(.horizontal)
                    
                    // Subscribe button
                    Button(action: {
                        // Action will be added later
                    }) {
                        HStack {
                            Spacer()
                            Text(Localizable.string(Localizable.subscribeNow))
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
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Premium Comparison Table
private struct PremiumComparisonTable: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                // Benefits column
                Text(Localizable.string(Localizable.benefits))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                
                Divider()
                    .frame(height: 20)
                
                // Free column
                Text(Localizable.string(Localizable.free))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                
                Divider()
                    .frame(height: 20)
                
                // Premium column
                Text(Localizable.string(Localizable.premiumColumn))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("AppGreen"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.5))
            )
            
            // Table rows
            VStack(spacing: 0) {
                PremiumTableRow(
                    benefit: Localizable.string(Localizable.accessToAllWords),
                    freeAvailable: true,
                    premiumAvailable: true
                )
                
                Divider()
                    .padding(.horizontal, 16)
                
                PremiumTableRow(
                    benefit: Localizable.string(Localizable.noAds),
                    freeAvailable: false,
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
        }
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Premium Table Row
private struct PremiumTableRow: View {
    let benefit: String
    let freeAvailable: Bool
    let premiumAvailable: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Benefits column
            Text(benefit)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            
            Divider()
                .frame(height: 20)
            
            // Free column
            if freeAvailable {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color("AppGreen"))
                    .frame(maxWidth: .infinity)
            } else {
                Image(systemName: "minus")
                    .font(.title3)
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
            
            Divider()
                .frame(height: 20)
            
            // Premium column
            if premiumAvailable {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color("AppGreen"))
                    .frame(maxWidth: .infinity)
            } else {
                Image(systemName: "minus")
                    .font(.title3)
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PremiumView()
    }
}

