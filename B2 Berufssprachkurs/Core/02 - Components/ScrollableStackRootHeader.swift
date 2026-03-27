//
//  ScrollableStackRootHeader.swift
//  B2 Berufssprachkurs
//
//  Title + stack icon row that scrolls with the list (WordsListHeaderView-style).
//  Back is the system item from the parent NavigationStack (same stack as home → list).
//

import SwiftUI

/// Icon + title only (scrolls with list content).
struct ScrollableStackRootHeader: View {
    let accent: Color
    let icon: String
    let title: String
    /// When `false`, no `Divider` under the title (e.g. Favorites uses the list’s shorter inset separator only).
    var showsDivider: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent)
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.25), lineWidth: 0.6)
                        )
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                }

                Text(title)
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 10)

            if showsDivider {
                Divider()
            }
        }
    }
}
