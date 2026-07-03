//
//  StudyView.swift
//  B2 Berufssprachkurs
//
//  Flashcard study session screen with answer handling and progression.
//  Created: 19.11.25.
//

import SwiftData
import SwiftUI

// MARK: - Screen

struct StudyView: View {
    // MARK: Inputs

    @ObservedObject var dataService: DataService
    @ObservedObject private var languageManager = LanguageManager.shared

    let filterBySectionId: String?
    let studyAllMode: Bool
    let favoritesOnly: Bool
    let categoryFilter: String?

    // MARK: State & Environment

    @StateObject private var viewModel: StudyViewModel

    @Query(sort: \WordProgress.wordId) private var wordProgressRecords: [WordProgress]

    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showNotificationSoftPrompt = false
    @State private var hasCheckedSoftPromptThisSession = false

    // MARK: Initialization

    init(
        dataService: DataService,
        filterBySectionId: String? = nil,
        studyAllMode: Bool = false,
        favoritesOnly: Bool = false,
        categoryFilter: String? = nil
    ) {
        self.dataService = dataService
        self.filterBySectionId = filterBySectionId
        self.studyAllMode = studyAllMode
        self.favoritesOnly = favoritesOnly
        self.categoryFilter = categoryFilter
        _viewModel = StateObject(
            wrappedValue: StudyViewModel(
                filterBySectionId: filterBySectionId,
                studyAllMode: studyAllMode,
                favoritesOnly: favoritesOnly,
                categoryFilter: categoryFilter
            )
        )
    }

    // MARK: Derived Data

    private var isPremiumActive: Bool {
        subscriptionManager.isPremiumActive
    }

    private var progressTranslationById: [String: String] {
        wordProgressRecords.reduce(into: [String: String]()) { partialResult, record in
            partialResult[record.wordId] = record.translation
        }
    }

    private var wordProgressSyncFingerprint: String {
        wordProgressRecords
            .sorted { $0.wordId < $1.wordId }
            .map { "\($0.wordId)|\($0.translation)|\($0.lastUpdated.timeIntervalSince1970)" }
            .joined(separator: "#")
    }

    // MARK: Helpers

    private func cardCountLabel(count: Int) -> String {
        if count == 1 {
            return "\(count) \(Localizable.string(Localizable.card))"
        }
        return "\(count) \(Localizable.string(Localizable.cards))"
    }

    private func reloadSessionItems() {
        viewModel.loadStudyItems(
            dataService: dataService,
            progressTranslationById: progressTranslationById,
            isPremiumActive: isPremiumActive
        )
    }

    private func evaluateSoftPromptEligibilityIfNeeded() {
        guard !hasCheckedSoftPromptThisSession else { return }
        hasCheckedSoftPromptThisSession = true

        NotificationManager.shared.shouldPresentSoftPrompt { shouldPresent in
            guard shouldPresent else { return }
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showNotificationSoftPrompt = true
                }
            }
        }
    }

    private func requestReviewAfterStudySessionIfNeeded() async {
        try? await Task.sleep(for: .seconds(1.5))
        guard !Task.isCancelled else { return }
        RatingManager.shared.requestReviewIfEligible()
    }

    // MARK: Visual Style

    /// Uses item accent in favorites mode; otherwise uses stack accent.
    private func studyChromeAccent(for item: StudyItem) -> Color {
        favoritesOnly ? item.accentColor : viewModel.stackKind.accentColor
    }

    /// Uses a calm canvas tone for each color scheme.
    private var studyCanvasBackground: Color {
        switch colorScheme {
        case .dark:
            return Color(.systemBackground)
        case .light:
            fallthrough
        @unknown default:
            return Color(.systemGroupedBackground)
        }
    }

    // MARK: View Layout

    var body: some View {
        ZStack {
            studyCanvasBackground
                .ignoresSafeArea()

            if viewModel.studyItems.isEmpty {
                StudyEmptyStateView(
                    title: emptyStateTitle,
                    message: emptyStateMessage,
                    iconName: emptyStateIcon,
                    backgroundColor: studyCanvasBackground
                )
            } else if viewModel.currentIndex < viewModel.studyItems.count {
                ZStack(alignment: .bottomTrailing) {
                    VStack(spacing: 0) {
                        headerView
                            .padding(.top, 8)

                        Spacer()

                        let currentItem = viewModel.studyItems[viewModel.currentIndex]

                        StudyFlashCardView(
                            studyItem: currentItem,
                            currentContentType: $viewModel.currentContentType,
                            cardColor: studyChromeAccent(for: currentItem),
                            cardId: currentItem.wordId,
                            initialFlipped: viewModel.cardFlipped,
                            dataService: dataService,
                            buttonFeedback: $viewModel.buttonFeedback,
                            onSwipeCorrect: {
                                viewModel.advanceAfterAnswer(quality: 4)
                            },
                            onSwipeWrong: {
                                viewModel.advanceAfterAnswer(quality: 0)
                            }
                        )
                        .id("card-\(viewModel.currentIndex)")
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 1.2).combined(with: .opacity)
                            )
                        )
                        .padding(.horizontal, 20)
                        .accessibilityLabel(
                            String(
                                format: Localizable.string(Localizable.studyFlashcardPositionA11y),
                                viewModel.currentIndex + 1,
                                viewModel.studyItems.count
                            )
                        )
                        .accessibilityHint(Localizable.string(Localizable.studyFlashcardHintA11y))

                        StudyAnswerButtonsBar(
                            buttonFeedback: $viewModel.buttonFeedback,
                            onWrong: { viewModel.advanceAfterAnswer(quality: 0) },
                            onCorrect: { viewModel.advanceAfterAnswer(quality: 4) }
                        )

                        Spacer()
                    }

                    Button(action: {
                        let wid = viewModel.studyItems[viewModel.currentIndex].wordId
                        _ = dataService.toggleFavorite(wordId: wid)
                        HapticManager.shared.lightImpact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {}
                    }) {
                        let wid = viewModel.studyItems[viewModel.currentIndex].wordId
                        let isFav = dataService.isFavorite(wordId: wid)
                        Image(systemName: isFav ? "star.fill" : "star")
                            .font(.system(size: 24, weight: .regular, design: .default))
                            .foregroundColor(isFav ? Color("AppYellow") : .secondary)
                            .symbolEffect(.bounce, value: isFav)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    .accessibilityLabel(
                        dataService.isFavorite(wordId: viewModel.studyItems[viewModel.currentIndex].wordId)
                            ? Localizable.string(Localizable.studyFavoriteRemoveA11y)
                            : Localizable.string(Localizable.studyFavoriteAddA11y)
                    )
                    .accessibilityHint(Localizable.string(Localizable.studyFavoriteHintA11y))
                }
            }

            if showNotificationSoftPrompt {
                Color.black.opacity(0.32)
                    .ignoresSafeArea()
                    .transition(.opacity)

                NotificationSoftPromptView(
                    onAllow: {
                        NotificationManager.shared.handleSoftPromptAllow()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNotificationSoftPrompt = false
                        }
                    },
                    onAskMeLater: {
                        NotificationManager.shared.handleSoftPromptAskMeLater()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNotificationSoftPrompt = false
                        }
                    },
                    onNoThanks: {
                        NotificationManager.shared.handleSoftPromptNoThanks()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNotificationSoftPrompt = false
                        }
                    }
                )
                .transition(.scale(scale: 0.98).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.studyItems.isEmpty {
                ToolbarItem(placement: .principal) {
                    Text(Localizable.string(Localizable.study))
                        .font(.system(.headline, design: .default).weight(.regular))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                }
            } else {
                ToolbarItem(placement: .principal) {
                    Text(cardCountLabel(count: viewModel.studyItems.count))
                        .font(.system(.headline, design: .default).weight(.medium))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.lightImpact()
                        viewModel.reverseCard()
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.clockwise")
                            .navigationBarSymbolStyle()
                            .foregroundColor(viewModel.isReversed ? .green : .primary)
                    }
                    .accessibilityLabel(
                        viewModel.isReversed
                            ? Localizable.string(Localizable.studyReverseActiveA11y)
                            : Localizable.string(Localizable.studyReverseInactiveA11y)
                    )
                    .accessibilityHint(Localizable.string(Localizable.studyReverseHintA11y))
                    .accessibilityValue(
                        viewModel.isReversed
                            ? Localizable.string(Localizable.studyReverseValueActive)
                            : Localizable.string(Localizable.studyReverseValueInactive)
                    )
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .hidesBottomBarWhenPushed(true)
        .onDisappear {
            guard viewModel.recordStudySessionMetricsIfNeeded() else { return }
            Task {
                await requestReviewAfterStudySessionIfNeeded()
            }
        }
        .onAppear {
            reloadSessionItems()
            viewModel.cardFlipped = viewModel.isReversed
            // Start each session on translation.
            viewModel.currentContentType = .translation
            hasCheckedSoftPromptThisSession = false
        }
        .onChange(of: viewModel.currentIndex) { _, _ in
            if viewModel.currentIndex < viewModel.studyItems.count {
                let item = viewModel.studyItems[viewModel.currentIndex]
                if !StudyCardContentSupport.isContentTypeAvailable(viewModel.currentContentType, for: item) {
                    viewModel.currentContentType = StudyCardContentSupport.firstAvailableContentType(for: item)
                }
            } else if !viewModel.studyItems.isEmpty {
                // Show reminder prompt after a completed session.
                evaluateSoftPromptEligibilityIfNeeded()
            }
        }
        .onChange(of: dataService.wordsBySection) { _, _ in
            reloadSessionItems()
        }
        .onChange(of: languageManager.currentLanguage) { _, _ in
            reloadSessionItems()
        }
        .onChange(of: wordProgressSyncFingerprint) { _, _ in
            reloadSessionItems()
        }
        .onChange(of: dataService.userCustomWords.count) { _, _ in
            reloadSessionItems()
        }
        .onChange(of: viewModel.isReversed) { _, newValue in
            viewModel.cardFlipped = newValue
        }
        .alert(
            Localizable.string(Localizable.translationNotFound),
            isPresented: $viewModel.showTranslationMissingAlert
        ) {
            Button(Localizable.string(Localizable.ok), role: .cancel) {}
        } message: {
            Text(Localizable.string(Localizable.translationNotFoundMessage))
        }
    }

    // MARK: Components

    private var headerView: some View {
        VStack(spacing: 8) {
            if viewModel.currentIndex < viewModel.studyItems.count {
                StudyContentTypeChipRow(
                    item: viewModel.studyItems[viewModel.currentIndex],
                    accentColor: studyChromeAccent(for: viewModel.studyItems[viewModel.currentIndex]),
                    currentContentType: $viewModel.currentContentType,
                    showTranslationMissingAlert: $viewModel.showTranslationMissingAlert
                )
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Empty State

    private var hasSelectedWordsOrSections: Bool {
        if studyAllMode {
            return true
        }

        if let sectionId = filterBySectionId {
            let checkedWordIds = dataService.checkedWords[sectionId] ?? Set<String>()
            return !checkedWordIds.isEmpty || dataService.isSectionCompleted(sectionId: sectionId)
        } else {
            if let categoryFilter = categoryFilter {
                if categoryFilter == "VERBEN_" {
                    return dataService.hasAnyVerbenPracticeSelection(isPremium: isPremiumActive)
                }
                if categoryFilter == "ADJEKTIVE_" {
                    return dataService.hasAnyAdjektivePracticeSelection(isPremium: isPremiumActive)
                }
            }
            for lection in dataService.lections {
                if !isPremiumActive,
                   !DataService.GeneralWordsFreeTier.isLectionUnlockedWithoutPremium(lection.id) {
                    continue
                }
                if dataService.isLectionCompleted(lectionId: lection.id) {
                    return true
                }
                for section in lection.sections {
                    if dataService.isSectionCompleted(sectionId: section.id) {
                        return true
                    }
                    let checkedWordIds = dataService.checkedWords[section.id] ?? Set<String>()
                    if !checkedWordIds.isEmpty {
                        return true
                    }
                }
            }
            return false
        }
    }

    private var emptyStateIcon: String {
        if !hasSelectedWordsOrSections {
            return "checkmark.circle"
        }
        return "long.text.page.and.pencil"
    }

    private var emptyStateTitle: String {
        if !hasSelectedWordsOrSections {
            return Localizable.string(Localizable.noWordsSelected)
        }
        return Localizable.string(Localizable.translationNotFound)
    }

    private var emptyStateMessage: String {
        if !hasSelectedWordsOrSections {
            return Localizable.string(Localizable.noWordsSelectedMessage)
        }
        return Localizable.string(Localizable.translationNotFoundMessage)
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
        StudyView(dataService: DataService(), filterBySectionId: nil, studyAllMode: true)
    }
    .modelContainer(container)
}
