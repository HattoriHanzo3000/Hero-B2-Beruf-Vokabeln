//
//  StudyViewModel.swift
//  B2 Berufssprachkurs
//
//  View model for study flow, card state, and answer progression.
//  Created: 04.04.26.
//

import Combine
import SwiftUI

// MARK: - StudyViewModel

@MainActor
final class StudyViewModel: ObservableObject {
    let filterBySectionId: String?
    let studyAllMode: Bool
    let favoritesOnly: Bool
    let categoryFilter: String?

    private let spacedRepetition = SpacedRepetitionService.shared
    private let ratingManager = RatingManager.shared

    @Published var currentIndex = 0
    @Published var studyItems: [StudyItem] = []
    @Published var isReversed = false
    @Published var cardFlipped = false
    @Published var cardsAnswered = 0
    @Published var currentContentType: StudyCardContentType = .translation
    @Published var showTranslationMissingAlert = false
    @Published var buttonFeedback: StudyButtonFeedback?
    @Published var studySessionMetricsRecorded = false

    @AppStorage("studySessionCount") private var studySessionCount = 0

    init(
        filterBySectionId: String? = nil,
        studyAllMode: Bool = false,
        favoritesOnly: Bool = false,
        categoryFilter: String? = nil
    ) {
        self.filterBySectionId = filterBySectionId
        self.studyAllMode = studyAllMode
        self.favoritesOnly = favoritesOnly
        self.categoryFilter = categoryFilter
    }

    var stackKind: StudyStackKind {
        StudyStackKind.resolve(
            filterBySectionId: filterBySectionId,
            categoryFilter: categoryFilter,
            studyItems: studyItems,
            favoritesOnly: favoritesOnly
        )
    }

    func loadStudyItems(
        dataService: DataService,
        progressTranslationById: [String: String],
        isPremiumActive: Bool
    ) {
        studyItems = StudySessionBuilder.buildStudyItems(
            dataService: dataService,
            progressTranslationById: progressTranslationById,
            filterBySectionId: filterBySectionId,
            studyAllMode: studyAllMode,
            favoritesOnly: favoritesOnly,
            categoryFilter: categoryFilter,
            isPremiumActive: isPremiumActive,
            spacedRepetition: spacedRepetition
        )
        if currentIndex >= studyItems.count {
            currentIndex = 0
        }
    }

    /// Wrong answers use quality 0–2; correct use 4–5 (spaced repetition).
    func advanceAfterAnswer(quality: Int) {
        guard currentIndex < studyItems.count else { return }
        let currentItem = studyItems[currentIndex]
        let mode = studyMode(for: currentContentType)
        spacedRepetition.recordStudyResult(wordId: currentItem.wordId, mode: mode, quality: quality)

        cardsAnswered += 1

        withAnimation(.easeInOut(duration: 0.4)) {
            if currentIndex < studyItems.count - 1 {
                currentIndex += 1
            } else {
                studyItems = StudySessionBuilder.prioritizeItems(studyItems, spacedRepetition: spacedRepetition)
                currentIndex = 0
            }
            cardFlipped = isReversed
        }
    }

    func reverseCard() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isReversed.toggle()
            cardFlipped = isReversed
        }
    }

    func recordStudySessionMetricsIfNeeded() {
        guard !studySessionMetricsRecorded else { return }
        studySessionMetricsRecorded = true
        if cardsAnswered >= 3 {
            studySessionCount += 1
            if ratingManager.trackStudySession() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.ratingManager.requestRating()
                }
            }
        }
    }

    /// Maps flashcard chip (``StudyCardContentType``) → spaced-repetition lane.
    private func studyMode(for contentType: StudyCardContentType) -> StudyMode {
        switch contentType {
        case .synonym:
            return .synonyms
        case .explanation:
            return .explanation
        case .translation:
            return .translations
        }
    }
}
