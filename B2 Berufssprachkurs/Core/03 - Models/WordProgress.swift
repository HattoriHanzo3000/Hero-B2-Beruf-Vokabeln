//
//  WordProgress.swift
//  B2 Berufssprachkurs
//

import Foundation
import SwiftData

/// Persisted user progress per word. CloudKit-backed SwiftData requires optional fields or inline defaults
/// and cannot use `@Attribute(.unique)`; one row per `wordId` is enforced in code (see `upsertTranslation`).
@Model
final class WordProgress {
    var wordId: String = ""
    var translation: String = ""
    var isLearned: Bool = false
    var lastUpdated: Date = Date()

    init(
        wordId: String,
        translation: String = "",
        isLearned: Bool = false,
        lastUpdated: Date = .now
    ) {
        self.wordId = wordId
        self.translation = translation
        self.isLearned = isLearned
        self.lastUpdated = lastUpdated
    }

    @MainActor
    static func upsertTranslation(wordId: String, text: String, in context: ModelContext) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = wordId
        var descriptor = FetchDescriptor<WordProgress>(
            predicate: #Predicate<WordProgress> { $0.wordId == id }
        )
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            existing.translation = text
            existing.lastUpdated = Date()
        } else if !trimmed.isEmpty {
            context.insert(WordProgress(wordId: wordId, translation: text, lastUpdated: Date()))
        }
        try? context.save()
    }

    @MainActor
    static func deleteAll(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<WordProgress>()
        let all = try context.fetch(descriptor)
        for item in all {
            context.delete(item)
        }
        if context.hasChanges {
            try context.save()
        }
    }
}
