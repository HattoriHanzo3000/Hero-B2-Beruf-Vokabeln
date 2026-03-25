//
//  HolidaySeasonalBanner.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import StoreKit

struct HolidaySeasonalBanner: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var isAnimating = false
    @State private var shimmerOffset: CGFloat = -200
    
    // Computed properties for prices
    private var promotionalPrice: String {
        guard let product = subscriptionManager.products["hero.premium.quarterly"],
              let subscription = product.subscription else {
            // Return empty string if product not loaded (will be handled by UI)
            return ""
        }
        
        // Try to find the promotional offer "christmas.sale"
        // The offer ID should match the identifier from App Store Connect
        for offer in subscription.promotionalOffers {
            if offer.id == "christmas.sale" {
                // Get the price from the promotional offer
                return offer.displayPrice
            }
        }
        
        // If promotional offer not found, return empty (shouldn't happen if offer is configured)
        return ""
    }
    
    private var regularPrice: String {
        // Get the base price from the yearly product
        guard let product = subscriptionManager.products["hero.premium.quarterly"] else {
            // Return empty string if product not loaded (will be handled by UI)
            return ""
        }
        
        // The base subscription price is the product's regular price
        // Note: In StoreKit 2, product.displayPrice shows the best available price
        // When a promotional offer is available, it might show the promotional price
        // However, since we're getting the promotional price separately from the offer,
        // we use the product's price as the base subscription price
        return product.displayPrice
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Christmas icon (gift box)
                Image(systemName: "gift.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title
                    Text(Localizable.string(Localizable.holidaySeasonSale))
                        .font(.system(.headline, design: .rounded).weight(.black))
                        .foregroundColor(.white)
                    
                    // Description - dynamically insert promotional price
                    if !promotionalPrice.isEmpty {
                        Text(String(format: Localizable.string(Localizable.holidaySeasonSaleDescription), promotionalPrice))
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(.white.opacity(0.95))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Regular price
                    if !regularPrice.isEmpty {
                        HStack(spacing: 4) {
                            Text(Localizable.string(Localizable.regularPrice))
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                            Text(regularPrice)
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                                .strikethrough()
                        }
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.15, blue: 0.15), // Deep red
                                Color(red: 0.15, green: 0.65, blue: 0.15),  // Deep green
                                Color(red: 0.9, green: 0.7, blue: 0.1)     // Gold accent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.85, green: 0.15, blue: 0.15).opacity(0.4), radius: 15, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                // Shimmer effect - horizontal
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 150)
                    .offset(x: shimmerOffset)
                    .blur(radius: 12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .onAppear {
            // Icon animation
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
            
            // Shimmer animation - less frequent
            startShimmerAnimation()
        }
        .onDisappear {
            // Reset shimmer when view disappears
            shimmerOffset = -200
        }
    }
    
    private func startShimmerAnimation() {
        Task {
            while true {
                shimmerOffset = -200
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
                
                withAnimation(.linear(duration: 2.5)) {
                    shimmerOffset = 500
                }
                
                // Wait for animation to complete, then add a longer pause before next shimmer
                try? await Task.sleep(nanoseconds: 2_500_000_000) // Wait for animation
                try? await Task.sleep(nanoseconds: 4_000_000_000) // Additional pause (4 seconds) - less frequent
            }
        }
    }
}

#Preview {
    HolidaySeasonalBanner(subscriptionManager: SubscriptionManager.shared)
        .background(Color(.systemBackground))
}
