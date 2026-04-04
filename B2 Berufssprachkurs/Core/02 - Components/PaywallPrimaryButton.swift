//
//  PaywallPrimaryButton.swift
//  B2 Berufssprachkurs
//
//  Gradient CTA for subscribe / continue on the paywall.
//

import SwiftUI

struct PaywallPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    /// Outer horizontal inset for the capsule (paywall uses 24; Your Plan uses 8).
    var horizontalPadding: CGFloat = 24
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Spacer()
                        Text(title.uppercased())
                            .font(.system(.headline, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.85)
                            .allowsTightening(true)
                        Spacer()
                    }
                }
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
                .background(
                    shape
                        .fill(
                            LinearGradient(
                                colors: [Color("AppBlue"), Color("AppBlueThird")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(isEnabled ? 1.0 : 0.75)
                        .overlay(
                            shape
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.4)
                                .blendMode(.plusLighter)
                        )
                        .overlay(
                            shape
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                )
                .clipShape(shape)
                .shadow(color: .black.opacity(isEnabled ? 0.16 : 0.08), radius: 22, x: 0, y: 10)
                .scaleEffect(isEnabled ? 1 : 0.98)
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isEnabled)
            }
            .disabled(!isEnabled)
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 18)
            .background(Color.clear)
        }
    }
}
