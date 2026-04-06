//
//  WordsListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftData
import SwiftUI

struct WordsListView: View {
    let sectionId: String
    /// When set (e.g. opening from global search), scroll this row to the **vertical center** of the list after layout.
    var scrollToWordIdOnAppear: String? = nil
    /// Hidden when opened from global search — practice for this section is started from stack screens; search is for lookup.
    var showsPracticeButton: Bool = true
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject private var listUIState: LearningListsUIState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Query(sort: \WordProgress.wordId) private var wordProgressList: [WordProgress]

    private var progressByWordId: [String: WordProgress] {
        wordProgressList.reduce(into: [String: WordProgress]()) { partialResult, record in
            partialResult[record.wordId] = record
        }
    }

    private func userTranslation(for wordId: String) -> String {
        progressByWordId[wordId]?.translation ?? ""
    }

    @State private var navigateToStudy = false
    @State private var navigateToSettings = false
    @State private var focusedTranslationWordId: String?
    @StateObject private var keyboardNavBridge = WordListKeyboardNavBridge()
    @StateObject private var keyboardMetrics = WordListKeyboardMetrics()
    @State private var deepLinkScrollTask: Task<Void, Never>?

    private var words: [Word] {
        dataService.getWords(for: sectionId)
    }

    private var wordIds: Set<String> {
        Set(words.map(\.id))
    }

    private var headerInfo: (lectionTitle: String, sectionTitle: String, lectionNumber: String, sectionLetter: String)? {
        dataService.getLectionAndSection(for: sectionId)
    }

    private var isVerbenSection: Bool {
        sectionId.hasPrefix("VERBEN_")
    }

    private var isAdjektiveSection: Bool {
        sectionId.hasPrefix("ADJEKTIVE_")
    }

    private var stackPresentation: SectionStackPresentation.Info {
        SectionStackPresentation.wordListStack(for: sectionId)
    }

    private var prepositionSuffix: String {
        SectionStackPresentation.prepositionSuffix(from: sectionId)
    }

    private var wordsListScrollBinding: Binding<String?> {
        Binding(
            get: { listUIState.wordsListScrollWordId(for: sectionId) },
            set: { listUIState.setWordsListScrollWordId($0, for: sectionId) }
        )
    }

    private var listTranslationGroup: FavoriteGroupType {
        dataService.getGroupType(for: sectionId)
    }

    private var listTranslationTextColor: Color {
        WordListTranslationTextStyle.color(for: listTranslationGroup, colorScheme: colorScheme)
    }

    /// Bottom scroll inset: leave room for the flashcards FAB when shown, plus keyboard overlap while editing.
    private var wordsListBottomScrollMargin: CGFloat {
        let bottomBase: CGFloat = showsPracticeButton ? FlashcardsButton.fabSize + 24 : 24
        if focusedTranslationWordId != nil, keyboardMetrics.bottomOverlap > 1 {
            return max(bottomBase, max(120, keyboardMetrics.bottomOverlap * 0.42 + 56))
        }
        return bottomBase
    }

    private var printJobName: String {
        WordListPDFExport.printJobName(
            sectionId: sectionId,
            headerInfo: headerInfo,
            stack: stackPresentation,
            prepositionSuffix: prepositionSuffix,
            isVerbenOrAdjektive: isVerbenSection || isAdjektiveSection
        )
    }

    var body: some View {
        ZStack {
            LearningSurfaceColors.surface(forSectionId: sectionId)
                .ignoresSafeArea()

            ScrollViewReader { proxy in
                List {
                    listHeaderContent
                    wordRowsContent
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.never)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, 6, for: .scrollContent)
                .contentMargins(.bottom, wordsListBottomScrollMargin, for: .scrollContent)
                .contentMargins(.horizontal, 0, for: .scrollContent)
                .scrollPosition(id: wordsListScrollBinding, anchor: .center)
                .accessibilityLabel(Localizable.string(Localizable.wordsListA11yLabel))
                .accessibilityHint(Localizable.string(Localizable.wordsListA11yHint))
                .onChange(of: focusedTranslationWordId) { _, newValue in
                    syncTranslationKeyboardNavBridge()
                    guard let id = newValue else { return }
                    WordsListScrollHelpers.scrollFocusedRowForKeyboard(
                        proxy: proxy,
                        wordId: id,
                        keyboardBottomOverlap: keyboardMetrics.bottomOverlap,
                        delays: [0.35, 0.6, 0.95]
                    )
                }
                .onChange(of: keyboardMetrics.bottomOverlap) { _, newOverlap in
                    guard newOverlap > 1, let id = focusedTranslationWordId else { return }
                    WordsListScrollHelpers.scrollFocusedRowForKeyboard(
                        proxy: proxy,
                        wordId: id,
                        keyboardBottomOverlap: keyboardMetrics.bottomOverlap,
                        delays: [0.04, 0.26]
                    )
                }
                .onChange(of: words.count) { _, _ in
                    syncTranslationKeyboardNavBridge()
                }
                .onAppear {
                    centerListOnDeepLinkIfNeeded(using: proxy)
                }
                .onDisappear {
                    deepLinkScrollTask?.cancel()
                    deepLinkScrollTask = nil
                }
            }
        }
        .hidesBottomBarWhenPushed(true)
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                dataService: dataService,
                filterBySectionId: sectionId,
                studyAllMode: true
            )
            .environmentObject(dataService)
        }
        .fullScreenCover(isPresented: $navigateToSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(dataService)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                WordListPrintButton(
                    isEnabled: !words.isEmpty,
                    pdfURL: { try generatePDF() },
                    jobName: printJobName
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsPracticeButton {
                FlashcardsButton.bottomTrailingInset(
                    isEnabled: !words.isEmpty,
                    accent: stackPresentation.color,
                    inactiveTapBehavior: .silent
                ) {
                    navigateToStudy = true
                }
            }
        }
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

    @ViewBuilder
    private var listHeaderContent: some View {
        if isVerbenSection || isAdjektiveSection {
            SwiftUI.Section {
                EmptyView()
            } header: {
                WordsListHeaderView(
                    stackColor: stackPresentation.color,
                    stackIcon: stackPresentation.iconSystemName,
                    lectionTitle: "",
                    sectionTitle: prepositionSuffix,
                    lectionNumber: "",
                    sectionLetter: ""
                )
                .id("wl-header-\(sectionId)")
            }
        } else if let info = headerInfo {
            SwiftUI.Section {
                EmptyView()
            } header: {
                WordsListHeaderView(
                    stackColor: stackPresentation.color,
                    stackIcon: stackPresentation.iconSystemName,
                    lectionTitle: info.lectionTitle,
                    sectionTitle: info.sectionTitle,
                    lectionNumber: info.lectionNumber,
                    sectionLetter: info.sectionLetter
                )
                .id("wl-header-\(sectionId)")
            }
        }
    }

    private var wordRowsContent: some View {
        ForEach(words) { word in
            WordRow(
                word: word,
                isFavorite: dataService.isFavorite(wordId: word.id),
                dataService: dataService,
                translationTextColor: listTranslationTextColor,
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

    private func centerListOnDeepLinkIfNeeded(using proxy: ScrollViewProxy) {
        WordsListScrollHelpers.startDeepLinkCenterTask(
            replacing: &deepLinkScrollTask,
            proxy: proxy,
            scrollToWordIdOnAppear: scrollToWordIdOnAppear,
            listUIState: listUIState,
            sectionId: sectionId,
            wordIdsInList: wordIds,
            accessibilityReduceMotion: accessibilityReduceMotion
        )
    }

    private func syncTranslationKeyboardNavBridge() {
        guard let fid = focusedTranslationWordId,
              let idx = words.firstIndex(where: { $0.id == fid }) else {
            keyboardNavBridge.syncCanNavigate(canPrevious: false, canNext: false)
            return
        }
        keyboardNavBridge.syncCanNavigate(
            canPrevious: idx > 0,
            canNext: idx < words.count - 1
        )
    }

    private func navigateToPreviousTranslationField() {
        guard let fid = focusedTranslationWordId,
              let idx = words.firstIndex(where: { $0.id == fid }),
              idx > 0 else { return }
        focusedTranslationWordId = words[idx - 1].id
    }

    private func navigateToNextTranslationField() {
        guard let fid = focusedTranslationWordId,
              let idx = words.firstIndex(where: { $0.id == fid }),
              idx < words.count - 1 else { return }
        focusedTranslationWordId = words[idx + 1].id
    }

    private func generatePDF() throws -> URL {
        try WordListPDFExport.generateWordsListPDF(
            sectionId: sectionId,
            words: words,
            headerInfo: headerInfo,
            stack: stackPresentation,
            prepositionSuffix: prepositionSuffix,
            isVerbenSection: isVerbenSection,
            isAdjektiveSection: isAdjektiveSection,
            translationProvider: { userTranslation(for: $0.id) }
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WordProgress.self, configurations: config)
    NavigationStack {
        WordsListView(sectionId: "1A")
            .environmentObject(DataService())
            .environmentObject(LearningListsUIState.shared)
    }
    .modelContainer(container)
}
