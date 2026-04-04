//
//  FavoritesEmptyStateView.swift
//  B2 Berufssprachkurs
//
//  Centered empty state when the user has no favorite words (nav back stays in the bar).
//

import SwiftUI

struct FavoritesEmptyStateView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 14) {
                Image(systemName: "star")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                Text(Localizable.string(Localizable.noFavoritesFound))
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(Localizable.string(Localizable.noFavoritesFoundMessage))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 36)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
