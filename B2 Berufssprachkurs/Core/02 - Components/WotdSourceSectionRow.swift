//
//  WotdSourceSectionRow.swift
//  B2 Berufssprachkurs
//

import SwiftUI

/// One selectable row in the Word of the Day source list (lection subsection or preposition stack row).
struct WotdSourceSectionRow: View {
    /// When non-`nil`, shown as a small leading label (e.g. lection letter). Preposition-only rows omit this.
    var leadingGlyph: String?
    let title: String
    let isSelected: Bool
    let showProBadge: Bool
    let rowEnabled: Bool
    let showDividerBelow: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if let leadingGlyph {
                    Text(leadingGlyph)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                if showProBadge {
                    ProShieldBadge(
                        label: "PRO",
                        color: Color.primary.opacity(0.72),
                        showShimmer: false,
                        style: .compact
                    )
                }

                Spacer()

                BouncingSelectionCheckmark(isSelected: isSelected)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .opacity(rowEnabled ? 1.0 : 0.6)

            if showDividerBelow {
                Divider()
                    .overlay(Color.white.opacity(0.15))
            }
        }
    }
}
