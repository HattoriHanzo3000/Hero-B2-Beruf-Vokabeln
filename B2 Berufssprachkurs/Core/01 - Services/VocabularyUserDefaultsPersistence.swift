//
//  VocabularyUserDefaultsPersistence.swift
//  B2 Berufssprachkurs
//
//  UserDefaults keys and load/save for study completion and favorites (stable across refactors).
//

import Foundation

enum VocabularyUserDefaultsPersistence {
    enum Keys {
        static let completedLections = "completedLections"
        static let completedSections = "completedSections"
        static let favoriteWords = "favoriteWords"
    }

    static func loadCompletedState(from defaults: UserDefaults = .standard) -> (lections: Set<Int>, sections: Set<String>) {
        let lections: Set<Int>
        if let arr = defaults.array(forKey: Keys.completedLections) as? [Int] {
            lections = Set(arr)
        } else {
            lections = []
        }
        let sections: Set<String>
        if let arr = defaults.array(forKey: Keys.completedSections) as? [String] {
            sections = Set(arr)
        } else {
            sections = []
        }
        return (lections, sections)
    }

    static func saveCompletedState(lections: Set<Int>, sections: Set<String>, to defaults: UserDefaults = .standard) {
        defaults.set(Array(lections), forKey: Keys.completedLections)
        defaults.set(Array(sections), forKey: Keys.completedSections)
    }

    static func loadFavoriteWordIds(from defaults: UserDefaults = .standard) -> Set<String> {
        if let arr = defaults.array(forKey: Keys.favoriteWords) as? [String] {
            return Set(arr)
        }
        return []
    }

    static func saveFavoriteWordIds(_ ids: Set<String>, to defaults: UserDefaults = .standard) {
        defaults.set(Array(ids), forKey: Keys.favoriteWords)
    }

    /// Removes pre–SwiftData keys (study selection + favorites) from `UserDefaults`, e.g. on full app reset.
    static func removeLegacyProgressKeys(from defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: Keys.completedLections)
        defaults.removeObject(forKey: Keys.completedSections)
        defaults.removeObject(forKey: Keys.favoriteWords)
    }
}
