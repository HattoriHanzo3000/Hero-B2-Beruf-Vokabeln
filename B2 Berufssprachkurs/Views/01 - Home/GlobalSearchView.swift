//
//  GlobalSearchView.swift
//  B2 Berufssprachkurs
//
//  Global vocabulary search with navigation to matching word lists.
//  Created: 30.03.26.
//

import SwiftData
import SwiftUI

// MARK: - Search Models

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
    // MARK: Inputs

    @Binding var selectedSection: MainViewSection
    /// Stores the tab that should be restored when Search is dismissed.
    var sectionBeforeSearch: MainViewSection

    // MARK: State & Environment

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var dataService: DataService
    @EnvironmentObject private var listUIState: LearningListsUIState
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @Query(sort: \WordProgress.wordId) private var wordProgressList: [WordProgress]

    @State private var searchText = ""
    @State private var isSearchPresented = true
    @FocusState private var isSearchFieldFocused: Bool
    /// Cached results keep rendering fast while typing.
    @State private var searchResultRows: [SearchVocabularyRow] = []

    // MARK: Derived Data

    private var searchTabIsSelected: Bool { selectedSection == .search }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var progressByWordId: [String: String] {
        wordProgressList.reduce(into: [String: String]()) { partialResult, record in
            partialResult[record.wordId] = record.translation
        }
    }

    // MARK: Search Updates

    private func rebuildSearchResults() {
        let q = trimmedQuery
        guard !q.isEmpty else {
            searchResultRows = []
            return
        }
        searchResultRows = VocabularySearchEngine.matches(
            query: q,
            dataService: dataService,
            isPremium: subscriptionManager.isPremiumActive,
            userTranslation: { wordId in
                let t = progressByWordId[wordId] ?? ""
                return t.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        )
        .map { SearchVocabularyRow(sectionId: $0.sectionId, word: $0.word) }
    }

    // MARK: View Layout

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            if trimmedQuery.isEmpty {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchResultRows.isEmpty {
                ContentUnavailableView.search(text: trimmedQuery)
            } else {
                List(searchResultRows) { item in
                    NavigationLink(value: SearchListDestination(wordId: item.word.id, sectionId: item.sectionId)) {
                        SearchResultRow(
                            word: item.word,
                            sectionId: item.sectionId,
                            dataService: dataService,
                            userTranslation: effectiveTranslation(for: item.word)
                        )
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .contentMargins(.horizontal, 0, for: .scrollContent)
            }
        }
        .navigationTitle(Localizable.string(Localizable.searchVocabularyTitle))
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchText,
            isPresented: $isSearchPresented,
            placement: .automatic,
            prompt: Text(Localizable.string(Localizable.searchVocabularyPrompt))
        )
        .searchFocused($isSearchFieldFocused)
        .onAppear {
            rebuildSearchResults()
            scheduleSearchFieldFocus()
        }
        .onChange(of: searchText) { _, _ in rebuildSearchResults() }
        .onChange(of: subscriptionManager.isPremiumActive) { _, _ in rebuildSearchResults() }
        .onChange(of: wordProgressList) { _, _ in rebuildSearchResults() }
        .onChange(of: dataService.userCustomWords.count) { _, _ in rebuildSearchResults() }
        .onChange(of: isSearchPresented) { _, presented in
            guard !presented, selectedSection == .search else { return }
            // System often collapses `.searchable` while the app moves to background/inactive; that is not
            // the user leaving Search. Popping the tab there yields wrong `selectedSection` after a widget tap.
            guard scenePhase == .active else { return }
            searchText = ""
            isSearchFieldFocused = false
            selectedSection = sectionBeforeSearch
        }
        .onChange(of: searchTabIsSelected) { _, isSelected in
            if isSelected {
                isSearchPresented = true
                scheduleSearchFieldFocus()
            } else {
                isSearchPresented = true
            }
        }
        .navigationDestination(for: SearchListDestination.self) { dest in
            WordsListView(
                sectionId: dest.sectionId,
                scrollToWordIdOnAppear: dest.wordId,
                showsPracticeButton: false
            )
            .environmentObject(dataService)
            .environmentObject(listUIState)
        }
    }

    // MARK: Helpers

    private func scheduleSearchFieldFocus() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 120_000_000)
            isSearchFieldFocused = true
        }
    }

    private func effectiveTranslation(for word: Word) -> String {
        let stored = progressByWordId[word.id] ?? ""
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return stored }
        return word.translation
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WordProgress.self,
        CustomWordEntry.self,
        StudySelectionState.self,
        FavoriteWord.self,
        SpacedRepetitionRecord.self,
        configurations: config
    )
    NavigationStack {
        GlobalSearchView(selectedSection: .constant(.search), sectionBeforeSearch: .home)
    }
    .environmentObject(DataService())
    .environmentObject(LearningListsUIState.shared)
    .modelContainer(container)
}
