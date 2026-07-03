//
//  WordOfTheDayWidget.swift
//  B2 Berufssprachkurs
//
//  Widget configuration and timeline provider for Word of the Day.
//  Created: 08.04.26.
//

import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct WordOfTheDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> WordOfTheDayEntry {
        mockEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (WordOfTheDayEntry) -> Void) {
        completion(entryFromPayload(now: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordOfTheDayEntry>) -> Void) {
        completion(timelineFromPayload(now: Date()))
    }

    // MARK: - Private

    private func timelineFromPayload(now: Date) -> Timeline<WordOfTheDayEntry> {
        guard let payload = WidgetPayloadManager.loadPayload(),
              !payload.entries.isEmpty else {
            return Timeline(entries: [mockEntry()], policy: .after(now.addingTimeInterval(3_600)))
        }

        let entries = payload.entries.map(entry(from:))
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func entryFromPayload(now: Date) -> WordOfTheDayEntry {
        guard let payload = WidgetPayloadManager.loadPayload(),
              !payload.entries.isEmpty else {
            return mockEntry()
        }

        let entries = payload.entries.map(entry(from:))
        if let active = entries.last(where: { $0.date <= now }) {
            return active
        }
        return entries.first ?? mockEntry()
    }

    private func entry(from payload: WidgetTimelineEntryPayload) -> WordOfTheDayEntry {
        WordOfTheDayEntry(
            date: payload.date,
            word: payload.word,
            translation: payload.translation,
            exampleSentence: payload.exampleSentence
        )
    }

    private func mockEntry() -> WordOfTheDayEntry {
        WordOfTheDayEntry(
            date: Date(),
            word: "die Herausforderung",
            translation: "Challenge",
            exampleSentence: "Das ist eine große Herausforderung für mich."
        )
    }
}

// MARK: - Widget

struct WordOfTheDayWidget: Widget {
    let kind: String = QuickAddDeepLink.wordOfTheDayWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordOfTheDayProvider()) { entry in
            WordOfTheDayView(entry: entry)
                .widgetURL(QuickAddDeepLink.wordOfTheDayURL)
                .containerBackground(for: .widget) {
                    WidgetBackgroundView()
                }
        }
        .configurationDisplayName(localizedString("widget_wotd_display_name"))
        .description(localizedString("widget_wotd_description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }

    private func localizedString(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", comment: "")
    }
}

// MARK: - Preview

#Preview("Word of the Day", as: .systemSmall) {
    WordOfTheDayWidget()
} timeline: {
    WordOfTheDayEntry(
        date: .now,
        word: "die Herausforderung",
        translation: "Challenge",
        exampleSentence: "Das ist eine große Herausforderung für mich."
    )
}
