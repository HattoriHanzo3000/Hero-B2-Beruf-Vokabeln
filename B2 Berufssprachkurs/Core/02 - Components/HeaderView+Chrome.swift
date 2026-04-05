//
//  HeaderView+Chrome.swift
//  B2 Berufssprachkurs
//

import SwiftUI

extension HeaderView {
    /// Hero header background for the legacy pinned header layout (horizontal green → blue bar).
    var pinnedHeaderGradientBackground: some View {
        LinearGradient(
            colors: colorScheme == .dark ? [
                Color("AppGreen").opacity(1.0),
                Color("AppBlue").opacity(1.0)
            ] : [
                Color("AppGreen"),
                Color("AppBlue")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .overlay(
            colorScheme == .dark ? Color.black.opacity(0.5) : Color.clear
        )
        .ignoresSafeArea(edges: .top)
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 12, x: 0, y: 6)
    }

    var mainHeaderContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if embedInScrollContent {
                greetingMascotAndWordSection
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background { homeHeroIslandBackground }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.22 : 0.45),
                                        Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.14), radius: 20, x: 0, y: 10)
            } else {
                greetingMascotAndWordSection
            }
        }
        .padding(.bottom, embedInScrollContent ? 8 : 18)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Liquid Glass island: material blur tinted with the same green → blue palette as the legacy pinned header / home wash.
    var homeHeroIslandBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(heroIslandGreenBlueTint)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(colorScheme == .dark ? 0.28 : 0.09))
        }
    }

    var heroIslandGreenBlueTint: LinearGradient {
        if colorScheme == .dark {
            LinearGradient(
                colors: [
                    Color("AppGreen").opacity(0.62),
                    Color("AppBlue").opacity(0.55)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            LinearGradient(
                colors: [
                    Color("AppGreen").opacity(0.52),
                    Color("AppBlue").opacity(0.46)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    var wordOfTheDayAccentColor: Color {
        if colorScheme == .dark {
            Color(red: 0.42, green: 0.82, blue: 0.58)
        } else {
            Color(red: 0.06, green: 0.38, blue: 0.26)
        }
    }

    var wotdDetailLabelFont: Font {
        .system(.subheadline, design: .default, weight: .bold).width(.condensed)
    }

    var wotdDetailValueFont: Font {
        .system(.subheadline, design: .default, weight: .medium).width(.condensed)
    }

    var proBadgeColor: Color {
        embedInScrollContent ? (colorScheme == .light ? .black : .white) : .white
    }

    var heroProSupplementFont: Font {
        .system(.caption2, weight: .medium).width(.expanded)
    }

    var isPremiumUser: Bool {
        isPremiumPreviewOverride ?? subscriptionManager.isPremiumActive
    }

    var showHeroFreeTrialCallout: Bool {
        subscriptionManager.hasCompletedInitialSubscriptionSync && !isPremiumUser
    }

    var heroEncouragementBoxHeight: CGFloat { mascotSize }

    func heroEncouragementScaledPointSize(containerWidth width: CGFloat) -> CGFloat {
        let reference: CGFloat = 235
        var size = 15 * min(max(width / reference, 0.85), 1.24)
        if horizontalSizeClass == .regular {
            size *= 1.05
        }
        return min(max(size, 13), 19)
    }
}
