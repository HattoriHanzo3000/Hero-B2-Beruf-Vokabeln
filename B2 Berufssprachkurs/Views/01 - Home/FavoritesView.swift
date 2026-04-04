//
//  FavoritesView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftData
import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var dataService: DataService
    @Query(sort: \WordProgress.wordId) private var wordProgressList: [WordProgress]

    @State private var navigateToStudy = false
    @State private var focusedTranslationWordId: String?
    @StateObject private var keyboardNavBridge = WordListKeyboardNavBridge()

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

    var body: some View {
        ZStack {
            Color("AppYellow").opacity(0.08)
                .ignoresSafeArea()

            if favoriteWords.isEmpty {
                FavoritesEmptyStateView()
            } else {
                favoritesListView
            }
        }
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
                        pdfURL: { generateFavoritesPDF() },
                        jobName: Localizable.string(Localizable.favorites)
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !favoriteWords.isEmpty {
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

    private func generateFavoritesPDF() -> URL {
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
        return PDFGenerationService.generateWordsListPDF(info: pdfInfo)
    }

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
                                HapticManager.shared.lightImpact()
                            }
                        )
                        .id(word.id)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollDismissesKeyboard(.never)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 8, for: .scrollContent)
            .contentMargins(.bottom, FlashcardsButton.fabSize + 24, for: .scrollContent)
            .accessibilityLabel("Favorites list")
            .accessibilityHint("List of favorite German words with translations, explanations, and synonyms")
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WordProgress.self, configurations: config)
    NavigationStack {
        FavoritesView()
            .environmentObject(DataService())
    }
    .modelContainer(container)
}
