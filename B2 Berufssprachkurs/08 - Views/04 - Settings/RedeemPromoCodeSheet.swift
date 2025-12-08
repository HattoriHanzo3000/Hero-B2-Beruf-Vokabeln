//
//  RedeemPromoCodeSheet.swift
//  B2 Berufssprachkurs
//
//  Created for promo code redemption sheet
//

import SwiftUI
import UIKit

struct RedeemPromoCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var promoCodeManager = PromoCodeManager.shared
    @State private var promoCodeText: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // App name from bundle
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Hero - Deutsch B2 Beruf"
    }
    
    // App icon
    private var appIcon: Image {
        if let iconName = UIApplication.shared.alternateIconName,
           let image = UIImage(named: iconName) {
            return Image(uiImage: image)
        }
        
        if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last,
           let image = UIImage(named: lastIcon) {
            return Image(uiImage: image)
        }
        
        // Fallback to AppIcon
        if let image = UIImage(named: "AppIcon") {
            return Image(uiImage: image)
        }
        
        // Final fallback
        return Image(systemName: "app.fill")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // App icon - centered at top
                    appIcon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.top, 80)
                    
                    // App name as subtext
                    Text(appName)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    // Title - "Redeem special offer" with gradient accent
                    Text(Localizable.string(Localizable.redeemSpecialOffer))
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
                        .padding(.top, 2)
                    
                    // Rounded text field for code entry
                    TextField(Localizable.string(Localizable.code), text: $promoCodeText)
                        .font(.system(.body, design: .rounded))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($isTextFieldFocused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    isTextFieldFocused ? Color("AppGreen") : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    
                    Spacer(minLength: 20)
                }
            }
            
            // Continue button at bottom
            VStack(spacing: 0) {
                Button(action: {
                    HapticManager.shared.mediumImpact()
                    let result = promoCodeManager.redeemPromoCode(promoCodeText)
                    alertMessage = result.message
                    showAlert = true
                    
                    if result.success {
                        promoCodeText = ""
                        HapticManager.shared.success()
                        // Dismiss after a short delay to show success
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    } else {
                        HapticManager.shared.error()
                    }
                }) {
                    HStack {
                        Spacer()
                        Text(Localizable.string(Localizable.continueButton))
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundColor(isButtonEnabled ? .white : .secondary)
                        Spacer()
                    }
                    .frame(height: 56)
                    .background(
                        Group {
                            if isButtonEnabled {
                                LinearGradient(
                                    colors: [
                                        Color("AppGreen"),
                                        Color("AppBlue")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                Color(.systemGray4)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: isButtonEnabled ? Color("AppGreen").opacity(0.4) : Color.clear, radius: isButtonEnabled ? 12 : 0, x: 0, y: isButtonEnabled ? 6 : 0)
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
        .alert(Localizable.string(Localizable.promoCode), isPresented: $showAlert) {
            Button(Localizable.string(Localizable.ok), role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // Focus text field when sheet appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
    }
    
    private var isButtonEnabled: Bool {
        !promoCodeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    RedeemPromoCodeSheet()
}
