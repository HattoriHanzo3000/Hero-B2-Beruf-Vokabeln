//
//  FavoriteWord.swift
//  B2 Berufssprachkurs
//
//  One row per favorited word ID. CloudKit-backed when sync is on.
//

import Foundation
import SwiftData

@Model
final class FavoriteWord {
    var wordId: String = ""
    var addedAt: Date = Date()

    init(wordId: String, addedAt: Date = Date()) {
        self.wordId = wordId
        self.addedAt = addedAt
    }

    @MainActor
    static func deleteAll(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<FavoriteWord>()
        let all = try context.fetch(descriptor)
        for item in all {
            context.delete(item)
        }
        if context.hasChanges {
            try context.save()
        }
    }
}
