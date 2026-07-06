//
//  SpacedRepetitionRecord.swift
//  B2 Berufssprachkurs
//
//  SM-2 card state per word. CloudKit-backed when sync is on.
//

import Foundation
import SwiftData

@Model
final class SpacedRepetitionRecord {
    var wordId: String = ""
    var easeFactor: Double = 2.5
    var interval: Int = 0
    var repetitions: Int = 0
    var lastReviewDate: Date?
    var nextReviewDate: Date?

    init(
        wordId: String,
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0,
        lastReviewDate: Date? = nil,
        nextReviewDate: Date? = nil
    ) {
        self.wordId = wordId
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
        self.lastReviewDate = lastReviewDate
        self.nextReviewDate = nextReviewDate
    }

    @MainActor
    static func deleteAll(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<SpacedRepetitionRecord>()
        let all = try context.fetch(descriptor)
        for item in all {
            context.delete(item)
        }
        if context.hasChanges {
            try context.save()
        }
    }
}
