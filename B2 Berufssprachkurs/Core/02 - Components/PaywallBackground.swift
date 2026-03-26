//
//  PaywallBackground.swift
//  B2 Berufssprachkurs
//
//  Green gradient + liquid-glass highlight behind the paywall scroll content.
//

import SwiftUI

struct PaywallBackground: View {
    var body: some View {
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
    }
}
