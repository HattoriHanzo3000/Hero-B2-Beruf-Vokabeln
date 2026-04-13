//
//  FavoritesStore.swift
//  B2 Berufssprachkurs
//
//  Persists and manages favorite word IDs with optional SwiftData binding.
//  Created: 05.04.26.
//

import Combine
import Foundation
import SwiftData

// MARK: - Store

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favoriteWordIds: Set<String> = []

    private var modelContext: ModelContext?

    init() {}

    func bind(modelContext: ModelContext) {
        self.modelContext = modelContext
        reloadFromStore()
    }

    var count: Int { favoriteWordIds.count }

    /// Removes or adds a favorite (no cap for free or Pro users).
    @discardableResult
    func toggle(wordId: String) -> Bool {
        if favoriteWordIds.contains(wordId) {
            favoriteWordIds.remove(wordId)
        } else {
            favoriteWordIds.insert(wordId)
        }
        persist()
        return true
    }

    func contains(wordId: String) -> Bool {
        favoriteWordIds.contains(wordId)
    }

    func reset() {
        favoriteWordIds.removeAll()
        if let context = modelContext {
            try? FavoriteWord.deleteAll(in: context)
        }
    }

    private func reloadFromStore() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<FavoriteWord>(sortBy: [SortDescriptor(\.addedAt)])
        let rows = (try? context.fetch(descriptor)) ?? []
        favoriteWordIds = Set(rows.map(\.wordId))
    }

    private func persist() {
        guard let context = modelContext else { return }
        let existing = (try? context.fetch(FetchDescriptor<FavoriteWord>())) ?? []
        let existingSet = Set(existing.map(\.wordId))

        for row in existing where !favoriteWordIds.contains(row.wordId) {
            context.delete(row)
        }
        for id in favoriteWordIds where !existingSet.contains(id) {
            context.insert(FavoriteWord(wordId: id))
        }
        try? context.save()
    }
}
