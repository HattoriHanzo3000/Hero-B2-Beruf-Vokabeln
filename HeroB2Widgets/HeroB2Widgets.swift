//
//  HeroB2Widgets.swift
//  HeroB2Widgets
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WordOfTheDayEntry {
        mockEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (WordOfTheDayEntry) -> ()) {
        completion(mockEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordOfTheDayEntry>) -> ()) {
        let timeline = Timeline(entries: [mockEntry()], policy: .atEnd)
        completion(timeline)
    }
    
    private func mockEntry() -> WordOfTheDayEntry {
        WordOfTheDayEntry(
            date: Date(),
            word: "die Herausforderung",
            translation: "Challenge",
            explanation: "Eine schwierige Aufgabe, die man bewältigen muss.",
            exampleSentence: "Das ist eine große Herausforderung für mich.",
            synonyms: "die Aufgabe, die Hürde",
            sectionIcon: "book.fill"
        )
    }
}

struct HeroWordOfTheDayWidget: Widget {
    let kind: String = "HeroWordOfTheDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                HeroWordOfTheDayView(entry: entry)
                    .containerBackground(for: .widget) {
                        HeroWidgetBackground()
                    }
            } else {
                HeroWordOfTheDayView(entry: entry)
                    .background(HeroWidgetBackground())
            }
        }
        .configurationDisplayName("Word of the Day")
        .description("Learn a new German word every day.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    HeroWordOfTheDayWidget()
} timeline: {
    WordOfTheDayEntry(
        date: .now,
        word: "die Herausforderung",
        translation: "Challenge",
        explanation: "Eine schwierige Aufgabe, die man bewältigen muss.",
        exampleSentence: "Das ist eine große Herausforderung für mich.",
        synonyms: "die Aufgabe, die Hürde",
        sectionIcon: "book.fill"
    )
}
