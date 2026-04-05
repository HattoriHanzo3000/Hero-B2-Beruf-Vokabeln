//
//  FavoritesStore.swift
//  B2 Berufssprachkurs
//
//  Favorite word IDs and UserDefaults persistence (`favoriteWords` key).
//

import Combine
import Foundation

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favoriteWordIds: Set<String> = []

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        favoriteWordIds = VocabularyUserDefaultsPersistence.loadFavoriteWordIds(from: userDefaults)
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
        persist()
    }

    private func persist() {
        VocabularyUserDefaultsPersistence.saveFavoriteWordIds(favoriteWordIds, to: userDefaults)
    }
}
