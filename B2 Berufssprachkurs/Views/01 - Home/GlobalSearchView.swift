//
//  GlobalSearchView.swift
//  B2 Berufssprachkurs
//
//  Full-text search across bundled vocabulary and “My Words”; matches German text,
//  user translations, explanations, examples, quiz hints, and synonyms.
//

import SwiftData
import SwiftUI

private struct SearchListDestination: Hashable {
    let wordId: String
    let sectionId: String
}

private struct SearchVocabularyRow: Identifiable {
    var id: String { "\(sectionId)|\(word.id)" }
    let sectionId: String
    let word: Word
}

struct GlobalSearchView: View {
    @EnvironmentObject private var dataService: DataService
    @EnvironmentObject private var listUIState: LearningListsUIState
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @Query(sort: \WordProgress.wordId) private var wordProgressList: [WordProgress]

    @State private var searchText = ""

    private var progressByWordId: [String: String] {
        Dictionary(uniqueKeysWithValues: wordProgressList.map { ($0.wordId, $0.translation) })
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: [SearchVocabularyRow] {
        VocabularySearchEngine.matches(
            query: trimmedQuery,
            dataService: dataService,
            isPremium: subscriptionManager.isPremiumActive,
            userTranslation: { wordId in
                let t = progressByWordId[wordId] ?? ""
                return t.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        )
        .map { SearchVocabularyRow(sectionId: $0.sectionId, word: $0.word) }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            if trimmedQuery.isEmpty {
                ContentUnavailableView {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityHidden(true)
                } description: {
                    Text(Localizable.string(Localizable.searchVocabularyHint))
                }
            } else if results.isEmpty {
                ContentUnavailableView.search(text: trimmedQuery)
            } else {
                List(results) { item in
                    NavigationLink(value: SearchListDestination(wordId: item.word.id, sectionId: item.sectionId)) {
                        SearchResultRow(
                            word: item.word,
                            sectionId: item.sectionId,
                            dataService: dataService,
                            userTranslation: effectiveTranslation(for: item.word),
                            colorScheme: colorScheme
                        )
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(Localizable.string(Localizable.searchVocabularyTitle))
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(verbatim: "")
        )
        .navigationDestination(for: SearchListDestination.self) { dest in
            WordsListView(sectionId: dest.sectionId, scrollToWordIdOnAppear: dest.wordId)
                .environmentObject(dataService)
                .environmentObject(listUIState)
        }
    }

    private func effectiveTranslation(for word: Word) -> String {
        let stored = progressByWordId[word.id] ?? ""
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return stored }
        return word.translation
    }
}

// MARK: - Row

private struct SearchResultRow: View {
    let word: Word
    let sectionId: String
    @ObservedObject var dataService: DataService
    let userTranslation: String
    let colorScheme: ColorScheme

    private var group: DataService.FavoriteGroupType {
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

// MARK: - Search engine

enum VocabularySearchEngine {
    private static let compareOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    static func matches(
        query: String,
        dataService: DataService,
        isPremium: Bool,
        userTranslation: (String) -> String
    ) -> [(sectionId: String, word: Word)] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        var pairs: [(sectionId: String, word: Word)] = []
        for (sectionId, words) in dataService.wordsBySection {
            guard dataService.isSectionIncludedInGlobalSearch(sectionId: sectionId, isPremium: isPremium) else { continue }
            for word in words {
                pairs.append((sectionId, word))
            }
        }
        for word in dataService.userCustomWords {
            pairs.append((DataService.userMyWordsSectionId, word))
        }

        let filtered = pairs.filter { pair in
            haystack(for: pair.word, userTranslation: userTranslation(pair.word.id))
                .contains { field in
                    field.range(of: q, options: compareOptions) != nil
                }
        }

        return filtered.sorted { lhs, rhs in
            let o0 = rank(word: lhs.word, query: q)
            let o1 = rank(word: rhs.word, query: q)
            if o0 != o1 { return o0 < o1 }
            if lhs.word.german != rhs.word.german {
                return lhs.word.german.localizedCaseInsensitiveCompare(rhs.word.german) == .orderedAscending
            }
            return lhs.sectionId < rhs.sectionId
        }
    }

    private static func haystack(for word: Word, userTranslation: String) -> [String] {
        var parts: [String] = [
            word.german,
            userTranslation,
            word.translation,
            word.explanation ?? "",
            word.example ?? "",
            word.quiz ?? ""
        ]
        if let syn = word.synonyms {
            parts.append(syn.joined(separator: " "))
        }
        return parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    /// Lower rank value = earlier in the list (stronger match).
    private static func rank(word: Word, query: String) -> Int {
        let g = word.german
        if g.range(of: query, options: [.anchored, .caseInsensitive, .diacriticInsensitive]) != nil {
            return 0
        }
        if g.range(of: query, options: compareOptions) != nil {
            return 1
        }
        return 2
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WordProgress.self, configurations: config)
    NavigationStack {
        GlobalSearchView()
    }
    .environmentObject(DataService())
    .environmentObject(LearningListsUIState.shared)
    .modelContainer(container)
}
