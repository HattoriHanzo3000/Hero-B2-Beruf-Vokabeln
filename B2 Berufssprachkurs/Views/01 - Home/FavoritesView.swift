//
//  FavoritesView.swift
//  B2 Berufssprachkurs
//
//  List and manage favorite words with quick study access.
//  Created: 26.11.25.
//

import SwiftData
import SwiftUI

// MARK: - Screen

struct FavoritesView: View {
    // MARK: State & Environment

    @EnvironmentObject private var dataService: DataService
    @Query(sort: \WordProgress.wordId) private var wordProgressList: [WordProgress]

    @State private var navigateToStudy = false
    @State private var focusedTranslationWordId: String?
    @StateObject private var keyboardNavBridge = WordListKeyboardNavBridge()

    // MARK: Derived Data

    private var progressByWordId: [String: WordProgress] {
        wordProgressList.reduce(into: [String: WordProgress]()) { partialResult, record in
            partialResult[record.wordId] = record
        }
    }

    private func userTranslation(for wordId: String) -> String {
        let progressText = progressByWordId[wordId]?.translation ?? ""
        if !progressText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return progressText
        }
        return favoriteWords.first(where: { $0.id == wordId })?.translation ?? ""
    }

    var favoriteWords: [Word] {
        dataService.getFavoriteWords()
    }

    // MARK: View Layout

    var body: some View {
        ZStack {
            LearningStackType.favorites.learningSurfaceBackground
                .ignoresSafeArea()

            if favoriteWords.isEmpty {
                FavoritesEmptyStateView()
            } else {
                favoritesListView
            }
        }
        .floatingKeyboardAccessory(
            isVisible: focusedTranslationWordId != nil,
            canGoPrevious: keyboardNavBridge.canGoToPrevious,
            canGoNext: keyboardNavBridge.canGoToNext,
            onPrevious: navigateToPreviousTranslationField,
            onNext: navigateToNextTranslationField,
            onDone: { focusedTranslationWordId = nil }
        )
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                dataService: dataService,
                filterBySectionId: nil,
                studyAllMode: false,
                favoritesOnly: true
            )
            .environmentObject(dataService)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !favoriteWords.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    WordListPrintButton(
                        pdfURL: { try generateFavoritesPDF() },
                        jobName: Localizable.string(Localizable.favorites)
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !favoriteWords.isEmpty, focusedTranslationWordId == nil {
                FlashcardsButton.bottomTrailingInset(
                    isEnabled: true,
                    accent: Color("AppYellow"),
                    inactiveTapBehavior: .silent
                ) {
                    navigateToStudy = true
                }
            }
        }
        .hidesBottomBarWhenPushed(true)
        .environmentObject(keyboardNavBridge)
        .onAppear {
            keyboardNavBridge.attachHandlers(
                onPrevious: navigateToPreviousTranslationField,
                onNext: navigateToNextTranslationField,
                onDismiss: { focusedTranslationWordId = nil }
            )
            syncTranslationKeyboardNavBridge()
        }
    }

    // MARK: Keyboard Navigation

    private func syncTranslationKeyboardNavBridge() {
        guard let fid = focusedTranslationWordId,
              let idx = favoriteWords.firstIndex(where: { $0.id == fid }) else {
            keyboardNavBridge.syncCanNavigate(canPrevious: false, canNext: false)
            return
        }
        keyboardNavBridge.syncCanNavigate(
            canPrevious: idx > 0,
            canNext: idx < favoriteWords.count - 1
        )
    }

    private func navigateToPreviousTranslationField() {
        guard let fid = focusedTranslationWordId,
              let idx = favoriteWords.firstIndex(where: { $0.id == fid }),
              idx > 0 else { return }
        focusedTranslationWordId = favoriteWords[idx - 1].id
    }

    private func navigateToNextTranslationField() {
        guard let fid = focusedTranslationWordId,
              let idx = favoriteWords.firstIndex(where: { $0.id == fid }),
              idx < favoriteWords.count - 1 else { return }
        focusedTranslationWordId = favoriteWords[idx + 1].id
    }

    // MARK: Export

    private func generateFavoritesPDF() throws -> URL {
        let wordData = WordListShareManager.wordDataForPDF(
            words: favoriteWords,
            translationProvider: { userTranslation(for: $0.id) }
        )
        let pdfInfo = PDFGenerationService.PDFInfo(
            lectionTitle: Localizable.string(Localizable.favorites),
            lectionNumber: nil,
            sectionTitle: "",
            sectionLetter: nil,
            headerColor: Color("AppYellow"),
            words: wordData,
            fileName: "Favorites",
            showsLectionSectionIndexing: false
        )
        return try PDFGenerationService.generateWordsListPDF(info: pdfInfo)
    }

    // MARK: Components

    private var favoritesListView: some View {
        ScrollViewReader { proxy in
            List {
                SwiftUI.Section {
                    EmptyView()
                } header: {
                    ScrollableStackRootHeader(
                        accent: Color("AppYellow"),
                        icon: "star.fill",
                        title: Localizable.string(Localizable.favorites),
                        showsDivider: false
                    )
                }

                SwiftUI.Section {
                    ForEach(favoriteWords) { word in
                        FavoriteWordRow(
                            word: word,
                            isFavorite: dataService.isFavorite(wordId: word.id),
                            dataService: dataService,
                            focusedTranslationWordId: $focusedTranslationWordId,
                            onFavoriteToggle: {
                                _ = dataService.toggleFavorite(wordId: word.id)
                            },
                            usesFloatingKeyboardAccessory: true
                        )
                        .id(word.id)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.never)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 6, for: .scrollContent)
            .contentMargins(.bottom, FlashcardsButton.fabSize + 24, for: .scrollContent)
            .contentMargins(.horizontal, 0, for: .scrollContent)
            .accessibilityLabel(Localizable.string(Localizable.favoritesListA11yLabel))
            .accessibilityHint(Localizable.string(Localizable.favoritesListA11yHint))
            .onChange(of: focusedTranslationWordId) { _, newValue in
                syncTranslationKeyboardNavBridge()
                guard let id = newValue else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
            .onChange(of: favoriteWords.count) { _, _ in
                syncTranslationKeyboardNavBridge()
            }
        }
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
        FavoritesView()
            .environmentObject(DataService())
    }
    .modelContainer(container)
}
