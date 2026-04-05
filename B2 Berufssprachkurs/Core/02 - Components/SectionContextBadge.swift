//
//  SectionContextBadge.swift
//  B2 Berufssprachkurs
//
//  Colored capsule label shared by global search and Favorites (section / stack origin).
//

import SwiftUI

struct SectionContextBadge: View {
    let caption: String
    let accentColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(caption)
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundStyle(accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(accentColor.opacity(colorScheme == .dark ? 0.22 : 0.12))
            )
    }
}
