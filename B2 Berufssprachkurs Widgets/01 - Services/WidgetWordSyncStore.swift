import Foundation

enum WidgetWordSyncStore {
    private static let appGroupId = QuickAddDeepLink.appGroupSuiteName
    private static let payloadKey = QuickAddDeepLink.wordOfTheDayPayloadKey

    static func loadEntry(now: Date = Date()) -> WordOfTheDayEntry? {
        // Avoid touching App Group prefs when the container is not available (previews, misconfigured targets).
        guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) != nil else {
            return nil
        }
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
            exampleSentence: payload["exampleSentence"] as? String
        )
    }
}
