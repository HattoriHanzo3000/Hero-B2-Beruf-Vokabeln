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
    let colorScheme: ColorScheme

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
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(word.german)
                    .font(.system(.body, design: .default, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text(contextCaption)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(accent.opacity(colorScheme == .dark ? 0.22 : 0.12))
                    )
            }
            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(word.german). \(contextCaption). \(subtitle)")
    }
}
