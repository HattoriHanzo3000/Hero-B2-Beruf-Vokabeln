//
//  SearchResultRow.swift
//  B2 Berufssprachkurs
//
//  Single row in global vocabulary search: lemma, context badge, subtitle (translation or explanation).
//

import SwiftUI

struct SearchResultRow: View {
    let word: Word
    let sectionId: String
    @ObservedObject var dataService: DataService
    let userTranslation: String

    private var group: FavoriteGroupType {
        dataService.getGroupType(for: sectionId)
    }

    private var accent: Color {
        group.color
    }

    private var subtitle: String {
        let trimmed = userTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if let ex = word.explanation?.trimmingCharacters(in: .whitespacesAndNewlines), !ex.isEmpty {
            return ex
        }
        if let ex = word.example?.trimmingCharacters(in: .whitespacesAndNewlines), !ex.isEmpty {
            return ex
        }
        return dataService.searchResultContextLabel(for: sectionId)
    }

    private var contextCaption: String {
        dataService.searchResultContextLabel(for: sectionId)
    }

    var body: some View {
        /// Stacks like `WordRow` / `FavoriteWordRow`: lemma + subtitle, then trailing context badge on its own row.
        VStack(alignment: .leading, spacing: 6) {
            Text(word.german)
                .font(.system(.callout, design: .default, weight: .regular))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(.callout, design: .default, weight: .regular))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Spacer(minLength: 0)
                SectionContextBadge(caption: contextCaption, accentColor: accent)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(word.german). \(contextCaption). \(subtitle)")
    }
}
