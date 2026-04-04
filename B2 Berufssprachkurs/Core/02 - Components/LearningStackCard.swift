//
//  LearningStackCard.swift
//  B2 Berufssprachkurs
//
//  Tappable stack card on the home hub (general words, verbs, adjectives, My Words, favorites).
//

import SwiftUI

struct LearningStackCard: View {
    let title: String
    let accent: Color
    let icon: String
    var isLocked: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Localized titles sometimes use `\n` (e.g. favorites); a single-line cap would hide the rest and show "…".
    private var displayTitle: String {
        title
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
    }

    /// Up to 2 lines for default–XXXLarge (long phrases + space instead of newline); more at accessibility sizes.
    private var titleLineRange: ClosedRange<Int> {
        dynamicTypeSize < .accessibility1 ? 1...2 : 1...4
    }

    private var titleMinimumScale: CGFloat {
        dynamicTypeSize < .accessibility1 ? 0.8 : 1.0
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(accent)
                .offset(x: 0, y: 14)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 7)

            ZStack {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(accent.opacity(0.8))
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(accent.opacity(0.5))
                }
            }
            .offset(x: 0, y: 8)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 5)

            ZStack {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(accent.opacity(0.4))
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(accent.opacity(0.25))
                }

                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accent)
                            .frame(width: 48, height: 48)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                    }

                    HStack(alignment: .center, spacing: 8) {
                        Text(displayTitle)
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundColor(accent)
                            .multilineTextAlignment(.leading)
                            .lineLimit(titleLineRange)
                            .minimumScaleFactor(titleMinimumScale)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if isLocked {
                            ProShieldBadge(
                                label: "PRO",
                                color: accent.opacity(0.86),
                                showShimmer: false,
                                style: .compact
                            )
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
