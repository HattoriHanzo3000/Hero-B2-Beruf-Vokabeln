//
//  WidgetTranslationStore.swift
//  B2 Berufssprachkurs
//
//  Reads and writes Word of the Day translation overrides in the App Group container.
//  Created: 03.07.26.
//

import Foundation

enum WidgetTranslationStore {
    static func fileURL() -> URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: QuickAddDeepLink.appGroupSuiteName
        ) else { return nil }
        return container.appendingPathComponent(
            QuickAddDeepLink.wordOfTheDayTranslationsFileName,
            isDirectory: false
        )
    }

    static func load() -> [String: String] {
        guard let url = fileURL(),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return decoded
    }

    static func save(_ translations: [String: String]) {
        guard let url = fileURL(),
              let data = try? JSONEncoder().encode(translations)
        else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func upsert(wordId: String, translation: String) {
        var map = load()
        let trimmed = translation.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            map.removeValue(forKey: wordId)
        } else {
            map[wordId] = trimmed
        }
        save(map)
    }
}
