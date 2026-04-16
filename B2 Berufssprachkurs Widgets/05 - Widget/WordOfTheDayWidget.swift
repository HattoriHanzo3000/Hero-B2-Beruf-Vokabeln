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
        completion(WidgetWordSyncStore.loadEntry() ?? mockEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordOfTheDayEntry>) -> Void) {
        let entry = WidgetWordSyncStore.loadEntry() ?? mockEntry()
        let refresh = Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date().addingTimeInterval(10_800)
        let timeline = Timeline(entries: [entry], policy: .after(refresh))
        completion(timeline)
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
    let kind: String = "WordOfTheDayWidget"

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
