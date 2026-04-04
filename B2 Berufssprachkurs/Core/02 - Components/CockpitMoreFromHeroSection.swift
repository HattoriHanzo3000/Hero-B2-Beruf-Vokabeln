//
//  CockpitMoreFromHeroSection.swift
//  B2 Berufssprachkurs
//
//  Tappable “More from Hero” promo card opening the advertisement sheet.
//

import SwiftUI

struct CockpitMoreFromHeroSection: View {
    @Binding var showSheet: Bool

    var body: some View {
        Button {
            HapticManager.shared.lightImpact()
            showSheet = true
        } label: {
            CockpitCard(
                titleIcon: "sparkles",
                title: Localizable.string(Localizable.cockpitMoreFromHeroSubtitle),
                subtitle: nil
            ) {
                HStack(alignment: .top, spacing: 12) {
                    Image("MascotLaunch")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72, alignment: .top)
                        .accessibilityHidden(true)

                    Text(Localizable.string(Localizable.cockpitMoreFromHeroBody))
                        .font(.system(.subheadline, design: .default))
                        .italic()
                        .foregroundStyle(Color("AppGreen"))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(
            "\(Localizable.string(Localizable.cockpitMoreFromHeroSubtitle)). \(Localizable.string(Localizable.cockpitMoreFromHeroBody))"
        )
        .padding(.horizontal)
    }
}
