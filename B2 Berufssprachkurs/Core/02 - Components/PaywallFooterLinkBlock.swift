//
//  PaywallFooterLinkBlock.swift
//  B2 Berufssprachkurs
//
//  Footnote caption + AppBlue link (restore / redeem) shared by paywall and Your Plan.
//

import SwiftUI

struct PaywallFooterLinkBlock: View {
    let caption: String
    let actionTitle: String
    var isActionDisabled: Bool = false
    var horizontalPadding: CGFloat = 24
    let action: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text(caption)
                .font(.system(.footnote, design: .default).weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Button(action: action) {
                Text(actionTitle)
                    .font(.system(.footnote, design: .default).weight(.semibold))
                    .foregroundStyle(Color("AppBlue"))
            }
            .disabled(isActionDisabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .fontDesign(.default)
    }
}
