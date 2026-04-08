import SwiftUI
import WidgetKit

struct WordOfTheDayProvider: TimelineProvider {
    func placeholder(in context: Context) -> WordOfTheDayEntry {
        mockEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (WordOfTheDayEntry) -> Void) {
        completion(WidgetWordSyncStore.loadEntry() ?? mockEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordOfTheDayEntry>) -> Void) {
        let entry = WidgetWordSyncStore.loadEntry() ?? mockEntry()
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(refresh))
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

struct WordOfTheDayWidget: Widget {
    let kind: String = "WordOfTheDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordOfTheDayProvider()) { entry in
            if #available(iOS 17.0, *) {
                WordOfTheDayView(entry: entry)
                    .containerBackground(for: .widget) {
                        WidgetBackgroundView()
                    }
            } else {
                WordOfTheDayView(entry: entry)
                    .background(WidgetBackgroundView())
            }
        }
        .configurationDisplayName("Word of the Day")
        .description("Learn a new German word every day.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    WordOfTheDayWidget()
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
