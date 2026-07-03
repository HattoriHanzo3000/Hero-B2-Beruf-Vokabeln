//
//  MainAppWidgetTimelineGenerator.swift
//  B2 Berufssprachkurs
//
//  Pre-computes the Word of the Day widget timeline in the main app.
//  Created: 03.07.26.
//

import Foundation

enum MainAppWidgetTimelineGenerator {
    static func generate(
        wordsBySection: [String: [Word]]? = nil,
        now: Date = Date()
    ) {
        guard FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: QuickAddDeepLink.appGroupSuiteName
        ) != nil else {
            return
        }
        guard let defaults = UserDefaults(suiteName: QuickAddDeepLink.appGroupSuiteName) else {
            return
        }

        let vocabulary: [String: [Word]]
        if let wordsBySection {
            vocabulary = wordsBySection
            WidgetVocabularyCache.setCachedWordsBySection(wordsBySection)
        } else {
            vocabulary = WidgetVocabularyCache.wordsBySection
        }

        let entries = buildEntryPayloads(
            wordsBySection: vocabulary,
            defaults: defaults,
            now: now
        )
        WidgetPayloadManager.savePayload(entries: entries)
    }

    // MARK: - Private

    private static func buildEntryPayloads(
        wordsBySection: [String: [Word]],
        defaults: UserDefaults,
        now: Date
    ) -> [WidgetTimelineEntryPayload] {
        let periodicity = defaults.string(forKey: WordOfTheDayResolver.periodicityKey) ?? "24_hours"
        let hoursPerPeriod = WordOfTheDayResolver.hoursPerPeriod(from: periodicity)
        let lookahead = WordOfTheDayResolver.timelineLookaheadPeriodCount(hoursPerPeriod: hoursPerPeriod)
        let translations = WidgetTranslationStore.load()
        let calendar = Calendar.current
        let currentPeriodIndex = WordOfTheDayResolver.periodIndex(
            for: now,
            calendar: calendar,
            hoursPerPeriod: hoursPerPeriod
        )
        let year = calendar.component(.year, from: now)
        guard let currentPeriodStart = WordOfTheDayResolver.periodStartDate(
            periodIndex: currentPeriodIndex,
            year: year,
            hoursPerPeriod: hoursPerPeriod,
            calendar: calendar
        ) else {
            return []
        }

        var entries: [WidgetTimelineEntryPayload] = []
        entries.reserveCapacity(lookahead)

        for offset in 0..<lookahead {
            guard let periodStart = calendar.date(
                byAdding: .hour,
                value: offset * hoursPerPeriod,
                to: currentPeriodStart
            ) else { continue }
            guard let word = WordOfTheDayResolver.currentWord(
                from: wordsBySection,
                at: periodStart,
                defaults: defaults
            ) else { continue }

            entries.append(
                WidgetTimelineEntryPayload(
                    date: periodStart,
                    word: word.german,
                    translation: translations[word.id] ?? "",
                    exampleSentence: word.example
                )
            )
        }

        return entries
    }
}
