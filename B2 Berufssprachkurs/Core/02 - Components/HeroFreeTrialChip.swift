//
//  HeroFreeTrialChip.swift
//  B2 Berufssprachkurs
//
//  Orange “Start free trial” pill (tappable when paywall binding is provided).
//

import SwiftUI

struct HeroFreeTrialChip: View {
    let font: Font
    /// When non-`nil`, wraps content in a button that runs the closure (e.g. open paywall).
    var onTap: (() -> Void)?

    var body: some View {
        Group {
            if let onTap {
                Button {
                    HapticManager.shared.lightImpact()
                    onTap()
                } label: {
                    label
                }
                .buttonStyle(.plain)
            } else {
                label
            }
        }
    }

    private var label: some View {
        Text(Localizable.string(Localizable.startFreeTrial))
            .font(font)
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color("AppOrange"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.white, lineWidth: 0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
