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

    static func resetTranslationsMigrationFlag() {
        UserDefaults.standard.removeObject(forKey: translationsMigrationCompletedKey)
    }

    static func resetProgressMigrationFlags() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: studySelectionMigrationCompletedKey)
        defaults.removeObject(forKey: favoritesMigrationCompletedKey)
        defaults.removeObject(forKey: spacedRepetitionMigrationCompletedKey)
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

    private static func modeKeyForStudyMode(_ mode: StudyMode) -> String {
        switch mode {
        case .synonyms: return "synonyms"
        case .explanation: return "explanation"
        case .translations: return "translations"
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

        for (storageKey, card) in decoded where !storageKey.hasSuffix("_example") {
            guard let (wordId, mode) = SpacedRepetitionService.parseStorageKey(storageKey) else { continue }
            let modeRaw = modeKeyForStudyMode(mode)
            let wid = wordId
            var descriptor = FetchDescriptor<SpacedRepetitionRecord>(
                predicate: #Predicate<SpacedRepetitionRecord> { $0.wordId == wid && $0.studyModeRaw == modeRaw }
            )
            descriptor.fetchLimit = 1
            if (try? context.fetch(descriptor).first) != nil { continue }

            context.insert(SpacedRepetitionRecord(
                wordId: wordId,
                studyModeRaw: modeRaw,
                easeFactor: card.easeFactor,
                interval: card.interval,
                repetitions: card.repetitions,
                lastReviewDate: card.lastReviewDate,
                nextReviewDate: card.nextReviewDate
            ))
        }

        do {
            try context.save()
            defaults.set(true, forKey: spacedRepetitionMigrationCompletedKey)
        } catch {
            // Leave flag unset so a future launch can retry.
        }
    }
}
