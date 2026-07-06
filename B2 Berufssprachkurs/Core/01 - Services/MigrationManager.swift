//
//  MigrationManager.swift
//  B2 Berufssprachkurs
//
//  Coordinates data migrations between legacy and current persistence layers.
//  Created: 27.03.26.
//

import Foundation
import SwiftData

/// One-time import of user translations from JSON in Documents into SwiftData.
enum MigrationManager {
    static let translationsMigrationCompletedKey = "hasMigratedTranslationsToSwiftDataV1"

    /// One-time copy of study selection, favorites, and spaced repetition from `UserDefaults` into SwiftData.
    static let studySelectionMigrationCompletedKey = "hasMigratedStudySelectionToSwiftDataV2"
    static let favoritesMigrationCompletedKey = "hasMigratedFavoritesToSwiftDataV2"
    static let spacedRepetitionMigrationCompletedKey = "hasMigratedSpacedRepetitionToSwiftDataV2"
    static let spacedRepetitionSingleTrackConsolidationKey = "hasConsolidatedSpacedRepetitionToSingleTrackV3"

    private static let legacyStudyModeSuffixes = ["translations", "explanation", "synonyms"]

    static func resetTranslationsMigrationFlag() {
        UserDefaults.standard.removeObject(forKey: translationsMigrationCompletedKey)
    }

    static func resetProgressMigrationFlags() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: studySelectionMigrationCompletedKey)
        defaults.removeObject(forKey: favoritesMigrationCompletedKey)
        defaults.removeObject(forKey: spacedRepetitionMigrationCompletedKey)
        defaults.removeObject(forKey: spacedRepetitionSingleTrackConsolidationKey)
    }

    /// Filenames checked in order; `user_translations.json` wins on duplicate keys (current app export), then `translations.json` fills remaining.
    private static let documentsTranslationFilenames = [
        "user_translations.json",
        "translations.json"
    ]

    /// Migrates non-empty translations from Documents JSON into `WordProgress`. Runs at most once per install (UserDefaults gate).
    @MainActor
    static func runTranslationsImportIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: translationsMigrationCompletedKey) else { return }

        let merged = loadTranslationsFromDocuments()
        for (wordId, entry) in merged {
            let trimmed = entry.translation.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            upsertTranslation(wordId: wordId, translation: trimmed, context: context)
        }

        do {
            try context.save()
            defaults.set(true, forKey: translationsMigrationCompletedKey)
        } catch {
            // Leave flag unset so a future launch can retry after e.g. CloudKit/local store issues.
        }
    }

    /// Migrates local-only `UserDefaults` progress into CloudKit-backed SwiftData models (once per install).
    @MainActor
    static func migrateLegacyUserDefaultsProgressToSwiftDataIfNeeded(context: ModelContext) {
        migrateStudySelectionFromUserDefaultsIfNeeded(context: context)
        migrateFavoritesFromUserDefaultsIfNeeded(context: context)
        migrateSpacedRepetitionFromUserDefaultsIfNeeded(context: context)
    }

    /// Merges duplicate per-mode SRS rows into one record per `wordId` (translations lane preferred when mode is known from legacy keys).
    @MainActor
    static func consolidateSpacedRepetitionToSingleTrackIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: spacedRepetitionSingleTrackConsolidationKey) else { return }

        let descriptor = FetchDescriptor<SpacedRepetitionRecord>()
        guard let all = try? context.fetch(descriptor) else { return }

        var grouped: [String: [SpacedRepetitionRecord]] = [:]
        for row in all {
            grouped[row.wordId, default: []].append(row)
        }

        var didChange = false
        for (_, records) in grouped where records.count > 1 {
            guard let winner = pickSwiftDataConsolidationWinner(from: records) else { continue }
            for record in records where record.persistentModelID != winner.persistentModelID {
                context.delete(record)
                didChange = true
            }
        }

        if didChange {
            try? context.save()
        }
        defaults.set(true, forKey: spacedRepetitionSingleTrackConsolidationKey)
    }

    // MARK: - Legacy SRS key parsing

    /// Parses legacy cache keys `\(wordId)_\(mode)`; plain `wordId` keys pass through unchanged.
    static func legacyWordIdAndMode(from storageKey: String) -> (wordId: String, mode: String?)? {
        for suffix in legacyStudyModeSuffixes {
            let token = "_\(suffix)"
            guard storageKey.hasSuffix(token) else { continue }
            let wordId = String(storageKey.dropLast(token.count))
            guard !wordId.isEmpty else { return nil }
            return (wordId, suffix)
        }
        guard !storageKey.isEmpty else { return nil }
        return (storageKey, nil)
    }

    // MARK: - Private

    private static func loadTranslationsFromDocuments() -> UserTranslations {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return [:]
        }

        var result: UserTranslations = [:]
        for filename in documentsTranslationFilenames {
            let fileURL = documentsURL.appendingPathComponent(filename, isDirectory: false)
            guard let data = try? Data(contentsOf: fileURL),
                  let decoded = try? JSONDecoder().decode(UserTranslations.self, from: data)
            else { continue }

            for (key, value) in decoded where result[key] == nil {
                result[key] = value
            }
        }
        return result
    }

    private static func upsertTranslation(wordId: String, translation: String, context: ModelContext) {
        let id = wordId
        var descriptor = FetchDescriptor<WordProgress>(
            predicate: #Predicate<WordProgress> { $0.wordId == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor).first {
            existing.translation = translation
            existing.lastUpdated = Date()
        } else {
            context.insert(WordProgress(wordId: wordId, translation: translation, lastUpdated: Date()))
        }
    }

    private static func migrateStudySelectionFromUserDefaultsIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: studySelectionMigrationCompletedKey) else { return }

        let legacy = VocabularyUserDefaultsPersistence.loadCompletedState(from: defaults)
        let state = StudySelectionState.fetchOrInsertSingleton(in: context)
        state.completedLectionIds = Array(legacy.lections).sorted()
        state.completedSectionIds = Array(legacy.sections).sorted()
        state.lastUpdated = Date()

        do {
            try context.save()
            defaults.set(true, forKey: studySelectionMigrationCompletedKey)
        } catch {
            // Leave flag unset so a future launch can retry.
        }
    }

    private static func migrateFavoritesFromUserDefaultsIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: favoritesMigrationCompletedKey) else { return }

        let ids = VocabularyUserDefaultsPersistence.loadFavoriteWordIds(from: defaults)
        for id in ids {
            let wid = id
            var descriptor = FetchDescriptor<FavoriteWord>(
                predicate: #Predicate<FavoriteWord> { $0.wordId == wid }
            )
            descriptor.fetchLimit = 1
            if (try? context.fetch(descriptor).first) != nil { continue }
            context.insert(FavoriteWord(wordId: id))
        }

        do {
            try context.save()
            defaults.set(true, forKey: favoritesMigrationCompletedKey)
        } catch {
            // Leave flag unset so a future launch can retry.
        }
    }

    private static func migrateSpacedRepetitionFromUserDefaultsIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: spacedRepetitionMigrationCompletedKey) else { return }

        let studyDataKey = "spacedRepetitionStudyData"
        guard let data = defaults.data(forKey: studyDataKey),
              let decoded = try? JSONDecoder().decode([String: SpacedRepetitionService.StudyCardData].self, from: data)
        else {
            defaults.set(true, forKey: spacedRepetitionMigrationCompletedKey)
            return
        }

        var grouped: [String: [(mode: String?, card: SpacedRepetitionService.StudyCardData)]] = [:]
        for (storageKey, card) in decoded where !storageKey.hasSuffix("_example") {
            guard let (wordId, mode) = legacyWordIdAndMode(from: storageKey) else { continue }
            grouped[wordId, default: []].append((mode: mode, card: card))
        }

        for (wordId, entries) in grouped {
            let wid = wordId
            var descriptor = FetchDescriptor<SpacedRepetitionRecord>(
                predicate: #Predicate<SpacedRepetitionRecord> { $0.wordId == wid }
            )
            descriptor.fetchLimit = 1
            if (try? context.fetch(descriptor).first) != nil { continue }

            let winner = pickLegacyConsolidationWinner(from: entries)
            context.insert(SpacedRepetitionRecord(
                wordId: wordId,
                easeFactor: winner.easeFactor,
                interval: winner.interval,
                repetitions: winner.repetitions,
                lastReviewDate: winner.lastReviewDate,
                nextReviewDate: winner.nextReviewDate
            ))
        }

        do {
            try context.save()
            defaults.set(true, forKey: spacedRepetitionMigrationCompletedKey)
        } catch {
            // Leave flag unset so a future launch can retry.
        }
    }

    /// SwiftData rows no longer carry mode after V3; prefer highest repetitions, then earliest `nextReviewDate`.
    private static func pickSwiftDataConsolidationWinner(from records: [SpacedRepetitionRecord]) -> SpacedRepetitionRecord? {
        records.max(by: { lhs, rhs in
            if lhs.repetitions != rhs.repetitions {
                return lhs.repetitions < rhs.repetitions
            }
            let lhsNext = lhs.nextReviewDate ?? .distantPast
            let rhsNext = rhs.nextReviewDate ?? .distantPast
            return lhsNext > rhsNext
        })
    }

    /// Legacy UserDefaults keys still encode mode; translations lane matches historical session ordering.
    private static func pickLegacyConsolidationWinner(
        from entries: [(mode: String?, card: SpacedRepetitionService.StudyCardData)]
    ) -> SpacedRepetitionService.StudyCardData {
        if let translations = entries.first(where: { $0.mode == "translations" }) {
            return translations.card
        }
        return entries.max(by: { $0.card.repetitions < $1.card.repetitions })!.card
    }
}
