import Foundation

enum WidgetWordSyncStore {
    static let appGroupId = "group.com.gizatech.B2-Beruf"
    private static let payloadKey = "widget.wordOfTheDay.payload"

    static func loadEntry(now: Date = Date()) -> WordOfTheDayEntry? {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let payload = defaults.dictionary(forKey: payloadKey)
        else { return nil }

        guard
            let word = payload["word"] as? String,
            let translation = payload["translation"] as? String
        else { return nil }

        return WordOfTheDayEntry(
            date: now,
            word: word,
            translation: translation,
            explanation: payload["explanation"] as? String,
            exampleSentence: payload["exampleSentence"] as? String,
            synonyms: payload["synonyms"] as? String,
            sectionIcon: payload["sectionIcon"] as? String ?? "book.fill"
        )
    }
}
