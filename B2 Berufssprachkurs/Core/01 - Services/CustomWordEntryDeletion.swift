//
//  CustomWordEntryDeletion.swift
//  B2 Berufssprachkurs
//
//  Shared cleanup when removing user-created words: favorites + WordProgress + SwiftData entry.
//

import Foundation
import SwiftData

enum CustomWordEntryDeletion {
    /// Clears favorite state, deletes matching `WordProgress`, and deletes the entry. Does not save.
    static func purge(_ entry: CustomWordEntry, dataService: DataService, modelContext: ModelContext) {
        let wordId = entry.id
        if dataService.isFavorite(wordId: wordId) {
            dataService.toggleFavorite(wordId: wordId)
        }
        let wid = wordId
        var progressDescriptor = FetchDescriptor<WordProgress>(
            predicate: #Predicate<WordProgress> { $0.wordId == wid }
        )
        progressDescriptor.fetchLimit = 1
        if let progress = try? modelContext.fetch(progressDescriptor).first {
            modelContext.delete(progress)
        }
        modelContext.delete(entry)
    }

    /// Deletes a single entry and persists.
    static func deleteSingle(_ entry: CustomWordEntry, dataService: DataService, modelContext: ModelContext) {
        purge(entry, dataService: dataService, modelContext: modelContext)
        try? modelContext.save()
    }

    /// Deletes every entry in the array and persists once.
    static func deleteAll(_ entries: [CustomWordEntry], dataService: DataService, modelContext: ModelContext) {
        for entry in entries {
            purge(entry, dataService: dataService, modelContext: modelContext)
        }
        try? modelContext.save()
    }
}
