//
//  WidgetWotdTimelineBuilder.swift
//  B2 Berufssprachkurs
//
//  Maps pre-computed App Group payload entries into WidgetKit timeline models.
//  Created: 03.07.26.
//

import Foundation
import WidgetKit

enum WidgetWotdTimelineBuilder {
    static func makeTimeline(now: Date = Date()) -> Timeline<WordOfTheDayEntry> {
        guard let payload = WidgetPayloadManager.loadPayload(),
              !payload.entries.isEmpty else {
            return Timeline(entries: [mockEntry(date: now)], policy: .after(now.addingTimeInterval(3_600)))
        }

        let entries = payload.entries.map(entry(from:))
        return Timeline(entries: entries, policy: .atEnd)
    }

    static func entryForDisplay(now: Date = Date()) -> WordOfTheDayEntry {
        guard let payload = WidgetPayloadManager.loadPayload(),
              !payload.entries.isEmpty else {
            return mockEntry(date: now)
        }

        let entries = payload.entries.map(entry(from:))
        if let active = entries.last(where: { $0.date <= now }) {
            return active
        }
        return entries.first ?? mockEntry(date: now)
    }

    // MARK: - Private

    private static func entry(from payload: WidgetTimelineEntryPayload) -> WordOfTheDayEntry {
        WordOfTheDayEntry(
            date: payload.date,
            word: payload.word,
            translation: payload.translation,
            exampleSentence: payload.exampleSentence
        )
    }

    private static func mockEntry(date: Date) -> WordOfTheDayEntry {
        WordOfTheDayEntry(
            date: date,
            word: "die Herausforderung",
            translation: "Challenge",
            exampleSentence: "Das ist eine große Herausforderung für mich."
        )
    }
}
