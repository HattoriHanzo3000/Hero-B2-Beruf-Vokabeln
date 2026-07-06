//
//  DataService.swift
//  B2 Berufssprachkurs
//
//  Main data facade for vocabulary, progress, favorites, and app-wide study state.
//  Created: 19.11.25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
class DataService: ObservableObject {
    typealias ProgressWordScope = VocabularyCatalog.ProgressWordScope
    typealias GeneralWordsFreeTier = VocabularyCatalog.GeneralWordsFreeTier
    typealias VerbenFreeTier = VocabularyCatalog.VerbenFreeTier
    typealias AdjektiveFreeTier = VocabularyCatalog.AdjektiveFreeTier

    static let userMyWordsSectionId = VocabularyCatalog.userMyWordsSectionId

    @Published var lections: [Lection] = []
    @Published var wordsBySection: [String: [Word]] = [:]
    /// Populated from SwiftData `CustomWordEntry` (CloudKit when sync is on).
    @Published var userCustomWords: [Word] = []

    let studyProgress: StudyProgressStore
    let favorites: FavoritesStore

    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    private var didAttachSwiftData = false

    var completedSections: Set<String> { studyProgress.completedSections }
    var completedLections: Set<Int> { studyProgress.completedLections }
    var checkedWords: [String: Set<String>] { studyProgress.checkedWords }
    /// Word IDs marked as favorites (same meaning as before extraction).
    var favoriteWords: Set<String> { favorites.favoriteWordIds }

    init() {
        studyProgress = StudyProgressStore(userDefaults: userDefaults)
        favorites = FavoritesStore()

        studyProgress.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)

        favorites.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)

        loadData()
        studyProgress.reconcileWithGeneralLections(lections)
    }

    /// Binds SwiftData-backed stores (study selection, favorites, spaced repetition) and runs one-time `UserDefaults` migration.
    func attachSwiftDataPersistence(_ context: ModelContext) {
        guard !didAttachSwiftData else { return }
        didAttachSwiftData = true
        MigrationManager.migrateLegacyUserDefaultsProgressToSwiftDataIfNeeded(context: context)
        MigrationManager.consolidateSpacedRepetitionToSingleTrackIfNeeded(context: context)
        studyProgress.bind(modelContext: context)
        favorites.bind(modelContext: context)
        SpacedRepetitionService.shared.bind(modelContext: context)
        studyProgress.reconcileWithGeneralLections(lections)
    }

    func loadData() {
        let loaded = BundledVocabularyLoader.load()
        lections = loaded.lections
        wordsBySection = loaded.wordsBySection
        studyProgress.reconcileWithGeneralLections(lections)
    }

    func getWords(for sectionId: String) -> [Word] {
        if sectionId == Self.userMyWordsSectionId {
            return userCustomWords
        }
        return wordsBySection[sectionId] ?? []
    }

    func updateUserCustomWords(from entries: [CustomWordEntry]) {
        userCustomWords = entries
            .sorted {
                if $0.sortIndex != $1.sortIndex { return $0.sortIndex < $1.sortIndex }
                return $0.createdAt < $1.createdAt
            }
            .map { $0.asWord() }
    }

    func getBundleWordIds() -> [String] {
        wordsBySection.values.flatMap { $0.map(\.id) }
    }

    func getUserCustomWordIds() -> [String] {
        userCustomWords.map(\.id)
    }

    func getAllWordIds() -> [String] {
        getBundleWordIds() + getUserCustomWordIds()
    }

    func wordIds(for scope: ProgressWordScope) -> [String] {
        switch scope {
        case .app:
            return getBundleWordIds()
        case .mine:
            return getUserCustomWordIds()
        }
    }

    // MARK: - Study progress (forwards)

    func toggleWordChecked(wordId: String, in sectionId: String) {
        studyProgress.toggleWordChecked(
            wordId: wordId,
            in: sectionId,
            wordsInSection: getWords(for: sectionId),
            lections: lections
        )
    }

    func toggleAllWords(in sectionId: String) {
        studyProgress.toggleAllWords(
            in: sectionId,
            wordsInSection: getWords(for: sectionId),
            lections: lections
        )
    }

    func isWordChecked(wordId: String, in sectionId: String) -> Bool {
        studyProgress.isWordChecked(wordId: wordId, in: sectionId)
    }

    func toggleSectionCompleted(sectionId: String) {
        studyProgress.toggleSectionCompleted(sectionId: sectionId, lections: lections)
    }

    func isSectionCompleted(sectionId: String) -> Bool {
        studyProgress.isSectionCompleted(sectionId: sectionId)
    }

    func toggleLectionCompleted(lectionId: Int) {
        studyProgress.toggleLectionCompleted(lectionId: lectionId, lections: lections)
    }

    func isLectionCompleted(lectionId: Int) -> Bool {
        studyProgress.isLectionCompleted(lectionId: lectionId, lections: lections)
    }

    func isEverySectionCompleted(in lection: Lection) -> Bool {
        studyProgress.isEverySectionCompleted(in: lection)
    }

    func isAnySectionCompleted(in lection: Lection) -> Bool {
        studyProgress.isAnySectionCompleted(in: lection)
    }

    func toggleAllLections() {
        studyProgress.toggleAllLections(lections: lections)
    }

    func toggleAllGeneralWordsForStudy(isPremium: Bool) {
        studyProgress.toggleAllGeneralWordsForStudy(isPremium: isPremium, lections: lections)
    }

    func areAllLectionsCompleted() -> Bool {
        studyProgress.areAllLectionsCompleted(lections: lections)
    }

    func toggleVerbenCompleted() {
        studyProgress.toggleVerbenCompleted()
    }

    func toggleVerbenCompletedForStudy(isPremium: Bool) {
        studyProgress.toggleVerbenCompletedForStudy(isPremium: isPremium)
    }

    func isVerbenCompleted() -> Bool {
        studyProgress.isVerbenCompleted()
    }

    func hasAnyGeneralWordsPracticeSelection(isPremium: Bool) -> Bool {
        studyProgress.hasAnyGeneralWordsPracticeSelection(isPremium: isPremium, lections: lections)
    }

    func areAllGeneralWordsCompletedForStudy(isPremium: Bool) -> Bool {
        studyProgress.areAllGeneralWordsCompletedForStudy(isPremium: isPremium, lections: lections)
    }

    func sanitizeCompletedSelectionsForCurrentTier(isPremium: Bool) {
        studyProgress.sanitizeCompletedSelectionsForCurrentTier(isPremium: isPremium, lections: lections)
    }

    func hasAnyVerbenCompleted() -> Bool {
        studyProgress.hasAnyVerbenCompleted()
    }

    func hasAnyVerbenPracticeSelection(isPremium: Bool) -> Bool {
        studyProgress.hasAnyVerbenPracticeSelection(isPremium: isPremium)
    }

    func areAllVerbenCompletedForStudy(isPremium: Bool) -> Bool {
        studyProgress.areAllVerbenCompletedForStudy(isPremium: isPremium)
    }

    func toggleAdjektiveCompleted() {
        studyProgress.toggleAdjektiveCompleted()
    }

    func toggleAdjektiveCompletedForStudy(isPremium: Bool) {
        studyProgress.toggleAdjektiveCompletedForStudy(isPremium: isPremium)
    }

    func isAdjektiveCompleted() -> Bool {
        studyProgress.isAdjektiveCompleted()
    }

    func hasAnyAdjektiveCompleted() -> Bool {
        studyProgress.hasAnyAdjektiveCompleted()
    }

    func hasAnyAdjektivePracticeSelection(isPremium: Bool) -> Bool {
        studyProgress.hasAnyAdjektivePracticeSelection(isPremium: isPremium)
    }

    func areAllAdjektiveCompletedForStudy(isPremium: Bool) -> Bool {
        studyProgress.areAllAdjektiveCompletedForStudy(isPremium: isPremium)
    }

    func getWordOfTheDay() -> Word? {
        WordOfTheDayResolver.currentWord(from: wordsBySection, defaults: userDefaults)
    }

    // MARK: - Favorites

    var favoritesCount: Int { favorites.count }

    @discardableResult
    func toggleFavorite(wordId: String) -> Bool {
        favorites.toggle(wordId: wordId)
    }

    func isFavorite(wordId: String) -> Bool {
        favorites.contains(wordId: wordId)
    }

    func getFavoriteWords() -> [Word] {
        var list: [Word] = []
        let ids = favorites.favoriteWordIds
        for (_, words) in wordsBySection {
            for word in words where ids.contains(word.id) {
                list.append(word)
            }
        }
        for word in userCustomWords where ids.contains(word.id) {
            list.append(word)
        }
        return list
    }

    // MARK: - Reset

    func resetAllData() {
        studyProgress.resetProgressState()
        favorites.reset()

        VocabularyUserDefaultsPersistence.removeLegacyProgressKeys(from: userDefaults)
        MigrationManager.resetProgressMigrationFlags()

        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsURL.appendingPathComponent("user_translations.json")
            try? FileManager.default.removeItem(at: fileURL)
            let legacyFileURL = documentsURL.appendingPathComponent("translations.json")
            try? FileManager.default.removeItem(at: legacyFileURL)
        }

        MigrationManager.resetTranslationsMigrationFlag()

        wordsBySection.removeAll()
        loadData()

        SpacedRepetitionService.shared.resetAllStudyData()

        userDefaults.set(false, forKey: "hasSeenWelcomeVideo")
    }

    // MARK: - Global search

    func isSectionIncludedInGlobalSearch(sectionId: String, isPremium: Bool) -> Bool {
        if isPremium { return true }
        if sectionId == Self.userMyWordsSectionId { return true }
        if sectionId.hasPrefix("VERBEN_") {
            return Self.VerbenFreeTier.isVerbenSectionUnlockedWithoutPremium(sectionId)
        }
        if sectionId.hasPrefix("ADJEKTIVE_") {
            return Self.AdjektiveFreeTier.isAdjektiveSectionUnlockedWithoutPremium(sectionId)
        }
        guard let lection1 = lections.first(where: { $0.id == Self.GeneralWordsFreeTier.unlockedLectionId }) else {
            return false
        }
        return lection1.sections.contains { $0.id == sectionId }
    }

    func searchResultContextLabel(for sectionId: String) -> String {
        GlobalSearchFormatting.contextLabel(for: sectionId)
    }
}
