//
//  MigrationManager.swift
//  B2 Berufssprachkurs
//

import Foundation
import SwiftData

/// One-time import of user translations from JSON in Documents into SwiftData.
enum MigrationManager {
    static let translationsMigrationCompletedKey = "hasMigratedTranslationsToSwiftDataV1"

    /// When `true` (default), `ModelContainer` uses CloudKit. Set in Settings; takes effect after restarting the app.
    static let iCloudSyncEnabledKey = "iCloudSyncEnabled"

    static func resetTranslationsMigrationFlag() {
        UserDefaults.standard.removeObject(forKey: translationsMigrationCompletedKey)
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
}
