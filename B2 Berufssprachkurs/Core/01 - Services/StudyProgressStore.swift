//
//  StudyProgressStore.swift
//  B2 Berufssprachkurs
//
//  Persists and computes vocabulary study progress state.
//  Created: 05.04.26.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class StudyProgressStore: ObservableObject {
    @Published var checkedWords: [String: Set<String>] = [:]
    @Published var completedSections: Set<String> = []
    @Published var completedLections: Set<Int> = []

    private let userDefaults: UserDefaults
    private var modelContext: ModelContext?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Wire persistence after the shared SwiftData stack exists (``MainView`` / app root).
    func bind(modelContext: ModelContext) {
        self.modelContext = modelContext
        reloadFromStore()
    }

    /// Call after bundled `lections` are loaded so lection-level metadata matches section sets.
    func reconcileWithGeneralLections(_ lections: [Lection]) {
        reconcileLectionCompletionMetadataWithSectionState(lections: lections)
        persistSnapshot()
    }

    // MARK: - Checked words

    func toggleWordChecked(wordId: String, in sectionId: String, wordsInSection: [Word], lections: [Lection]) {
        if checkedWords[sectionId] == nil {
            checkedWords[sectionId] = []
        }
        if var checked = checkedWords[sectionId] {
            if checked.contains(wordId) {
                checked.remove(wordId)
            } else {
                checked.insert(wordId)
            }
            checkedWords[sectionId] = checked
            updateSectionCompletion(sectionId: sectionId, wordsInSection: wordsInSection, lections: lections)
        }
        persistSnapshot()
    }

    func toggleAllWords(in sectionId: String, wordsInSection: [Word], lections: [Lection]) {
        let allWordIds = Set(wordsInSection.map(\.id))
        let currentChecked = checkedWords[sectionId] ?? Set<String>()

        if allWordIds.isSubset(of: currentChecked) {
            checkedWords[sectionId] = Set<String>()
        } else {
            checkedWords[sectionId] = allWordIds
        }
        updateSectionCompletion(sectionId: sectionId, wordsInSection: wordsInSection, lections: lections)
        persistSnapshot()
    }

    func isWordChecked(wordId: String, in sectionId: String) -> Bool {
        checkedWords[sectionId]?.contains(wordId) ?? false
    }

    // MARK: - Section / lection completion

    func toggleSectionCompleted(sectionId: String, lections: [Lection]) {
        if completedSections.contains(sectionId) {
            completedSections.remove(sectionId)
        } else {
            completedSections.insert(sectionId)
        }
        syncLectionCompletionMetadata(forSectionId: sectionId, lections: lections)
        persistSnapshot()
    }

    func isSectionCompleted(sectionId: String) -> Bool {
        completedSections.contains(sectionId)
    }

    func toggleLectionCompleted(lectionId: Int, lections: [Lection]) {
        guard let lection = lections.first(where: { $0.id == lectionId }) else { return }

        let sectionIds = Set(lection.sections.map { $0.id })

        if completedLections.contains(lectionId) {
            completedLections.remove(lectionId)
            for sectionId in sectionIds {
                completedSections.remove(sectionId)
            }
        } else {
            completedLections.insert(lectionId)
            for sectionId in sectionIds {
                completedSections.insert(sectionId)
            }
        }
        persistSnapshot()
    }

    func isLectionCompleted(lectionId: Int, lections: [Lection]) -> Bool {
        guard let lection = lections.first(where: { $0.id == lectionId }) else {
            return completedLections.contains(lectionId)
        }
        return isEverySectionCompleted(in: lection)
    }

    func isEverySectionCompleted(in lection: Lection) -> Bool {
        let ids = lection.sections.map { $0.id }
        guard !ids.isEmpty else { return false }
        return ids.allSatisfy { completedSections.contains($0) }
    }

    func isAnySectionCompleted(in lection: Lection) -> Bool {
        lection.sections.contains { completedSections.contains($0.id) }
    }

    func toggleAllLections(lections: [Lection]) {
        let allSectionIds = Set(lections.flatMap { $0.sections.map { $0.id } })
        let allGeneralSelected = lections.allSatisfy { isEverySectionCompleted(in: $0) }

        if allGeneralSelected {
            for id in allSectionIds {
                completedSections.remove(id)
            }
        } else {
            for id in allSectionIds {
                completedSections.insert(id)
            }
        }
        reconcileLectionCompletionMetadataWithSectionState(lections: lections)
        persistSnapshot()
    }

    func toggleAllGeneralWordsForStudy(isPremium: Bool, lections: [Lection]) {
        if isPremium {
            toggleAllLections(lections: lections)
            return
        }
        guard let lection1 = lections.first(where: { $0.id == VocabularyCatalog.GeneralWordsFreeTier.unlockedLectionId }) else {
            return
        }
        let freeSectionIds = Set(lection1.sections.map(\.id))
        let isFullySelected = isEverySectionCompleted(in: lection1)
        if isFullySelected {
            completedSections.subtract(freeSectionIds)
        } else {
            completedSections.formUnion(freeSectionIds)
        }
        reconcileLectionCompletionMetadataWithSectionState(lections: lections)
        persistSnapshot()
    }

    func areAllLectionsCompleted(lections: [Lection]) -> Bool {
        guard !lections.isEmpty else { return false }
        return lections.allSatisfy { isEverySectionCompleted(in: $0) }
    }

    func toggleVerbenCompleted() {
        let ids = VocabularyCatalog.verbenSectionIds
        let allCompleted = ids.isSubset(of: completedSections)

        if allCompleted {
            for sectionId in ids {
                completedSections.remove(sectionId)
            }
        } else {
            for sectionId in ids {
                completedSections.insert(sectionId)
            }
        }
        persistSnapshot()
    }

    func toggleVerbenCompletedForStudy(isPremium: Bool) {
        if isPremium {
            toggleVerbenCompleted()
            return
        }
        let an = VocabularyCatalog.VerbenFreeTier.unlockedSectionId
        if completedSections.contains(an) {
            completedSections.remove(an)
        } else {
            completedSections.insert(an)
        }
        persistSnapshot()
    }

    func isVerbenCompleted() -> Bool {
        VocabularyCatalog.verbenSectionIds.isSubset(of: completedSections)
    }

    func hasAnyGeneralWordsPracticeSelection(isPremium: Bool, lections: [Lection]) -> Bool {
        let relevant: [Lection]
        if isPremium {
            relevant = lections
        } else {
            relevant = lections.filter { $0.id == VocabularyCatalog.GeneralWordsFreeTier.unlockedLectionId }
        }
        guard !relevant.isEmpty else { return false }
        if relevant.contains(where: { isLectionCompleted(lectionId: $0.id, lections: lections) }) { return true }
        for lection in relevant {
            for section in lection.sections {
                if isSectionCompleted(sectionId: section.id) { return true }
                if let checked = checkedWords[section.id], !checked.isEmpty { return true }
            }
        }
        return false
    }

    func areAllGeneralWordsCompletedForStudy(isPremium: Bool, lections: [Lection]) -> Bool {
        if isPremium {
            return areAllLectionsCompleted(lections: lections)
        }
        guard let lection1 = lections.first(where: { $0.id == VocabularyCatalog.GeneralWordsFreeTier.unlockedLectionId }) else {
            return false
        }
        return isEverySectionCompleted(in: lection1)
    }

    func sanitizeCompletedSelectionsForCurrentTier(isPremium: Bool, lections: [Lection]) {
        guard !isPremium else { return }

        let unlockedGeneralSectionIds = Set(
            lections
                .first(where: { $0.id == VocabularyCatalog.GeneralWordsFreeTier.unlockedLectionId })?
                .sections
                .map(\.id) ?? []
        )
        let allowedSectionIds = unlockedGeneralSectionIds
            .union([
                VocabularyCatalog.VerbenFreeTier.unlockedSectionId,
                VocabularyCatalog.AdjektiveFreeTier.unlockedSectionId
            ])

        completedSections = completedSections.intersection(allowedSectionIds)
        reconcileLectionCompletionMetadataWithSectionState(lections: lections)
        persistSnapshot()
    }

    func hasAnyVerbenCompleted() -> Bool {
        VocabularyCatalog.verbenSectionIds.contains { completedSections.contains($0) }
    }

    func hasAnyVerbenPracticeSelection(isPremium: Bool) -> Bool {
        if isPremium {
            return hasAnyVerbenCompleted()
        }
        let an = VocabularyCatalog.VerbenFreeTier.unlockedSectionId
        if isSectionCompleted(sectionId: an) { return true }
        if let checked = checkedWords[an], !checked.isEmpty { return true }
        return false
    }

    func areAllVerbenCompletedForStudy(isPremium: Bool) -> Bool {
        if isPremium {
            return isVerbenCompleted()
        }
        return isSectionCompleted(sectionId: VocabularyCatalog.VerbenFreeTier.unlockedSectionId)
    }

    func toggleAdjektiveCompleted() {
        let ids = VocabularyCatalog.adjektiveSectionIds
        let allCompleted = ids.isSubset(of: completedSections)

        if allCompleted {
            for sectionId in ids {
                completedSections.remove(sectionId)
            }
        } else {
            for sectionId in ids {
                completedSections.insert(sectionId)
            }
        }
        persistSnapshot()
    }

    func toggleAdjektiveCompletedForStudy(isPremium: Bool) {
        if isPremium {
            toggleAdjektiveCompleted()
            return
        }
        let an = VocabularyCatalog.AdjektiveFreeTier.unlockedSectionId
        if completedSections.contains(an) {
            completedSections.remove(an)
        } else {
            completedSections.insert(an)
        }
        persistSnapshot()
    }

    func isAdjektiveCompleted() -> Bool {
        VocabularyCatalog.adjektiveSectionIds.isSubset(of: completedSections)
    }

    func hasAnyAdjektiveCompleted() -> Bool {
        VocabularyCatalog.adjektiveSectionIds.contains { completedSections.contains($0) }
    }

    func hasAnyAdjektivePracticeSelection(isPremium: Bool) -> Bool {
        if isPremium {
            return hasAnyAdjektiveCompleted()
        }
        let an = VocabularyCatalog.AdjektiveFreeTier.unlockedSectionId
        if isSectionCompleted(sectionId: an) { return true }
        if let checked = checkedWords[an], !checked.isEmpty { return true }
        return false
    }

    func areAllAdjektiveCompletedForStudy(isPremium: Bool) -> Bool {
        if isPremium {
            return isAdjektiveCompleted()
        }
        return isSectionCompleted(sectionId: VocabularyCatalog.AdjektiveFreeTier.unlockedSectionId)
    }

    // MARK: - Reset

    func resetProgressState() {
        checkedWords.removeAll()
        completedSections.removeAll()
        completedLections.removeAll()
        if let context = modelContext {
            try? StudySelectionState.deleteAll(in: context)
            let fresh = StudySelectionState()
            context.insert(fresh)
            try? context.save()
        } else {
            VocabularyUserDefaultsPersistence.saveCompletedState(
                lections: [],
                sections: [],
                to: userDefaults
            )
        }
    }

    // MARK: - Private

    private func reloadFromStore() {
        guard let context = modelContext else { return }
        let state = StudySelectionState.fetchOrInsertSingleton(in: context)
        completedLections = Set(state.completedLectionIds)
        completedSections = Set(state.completedSectionIds)
        checkedWords = StudySelectionState.checkedWords(from: state.checkedWordsJSON)
    }

    private func persistSnapshot() {
        if let context = modelContext {
            let state = StudySelectionState.fetchOrInsertSingleton(in: context)
            state.completedLectionIds = Array(completedLections).sorted()
            state.completedSectionIds = Array(completedSections).sorted()
            state.checkedWordsJSON = StudySelectionState.json(from: checkedWords)
            state.lastUpdated = Date()
            try? context.save()
        } else {
            VocabularyUserDefaultsPersistence.saveCompletedState(
                lections: completedLections,
                sections: completedSections,
                to: userDefaults
            )
        }
    }

    private func syncLectionCompletionMetadata(forSectionId sectionId: String, lections: [Lection]) {
        guard let lection = lections.first(where: { $0.sections.contains { $0.id == sectionId } }) else { return }
        let sectionIds = Set(lection.sections.map { $0.id })
        guard !sectionIds.isEmpty else { return }
        if sectionIds.isSubset(of: completedSections) {
            completedLections.insert(lection.id)
        } else {
            completedLections.remove(lection.id)
        }
    }

    private func reconcileLectionCompletionMetadataWithSectionState(lections: [Lection]) {
        for lection in lections {
            let sectionIds = Set(lection.sections.map { $0.id })
            guard !sectionIds.isEmpty else { continue }
            if sectionIds.isSubset(of: completedSections) {
                completedLections.insert(lection.id)
            } else {
                completedLections.remove(lection.id)
            }
        }
    }

    private func updateSectionCompletion(sectionId: String, wordsInSection: [Word], lections: [Lection]?) {
        let checkedCount = checkedWords[sectionId]?.count ?? 0

        if !wordsInSection.isEmpty && checkedCount == wordsInSection.count {
            if !completedSections.contains(sectionId) {
                completedSections.insert(sectionId)
                if let lections {
                    syncLectionCompletionMetadata(forSectionId: sectionId, lections: lections)
                }
            }
        }
    }
}
