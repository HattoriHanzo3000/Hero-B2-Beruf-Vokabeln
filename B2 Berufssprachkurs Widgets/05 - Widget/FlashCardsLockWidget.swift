import SwiftUI
import WidgetKit

// MARK: - Lock Screen accessory (Study My Words, `.accessoryCircular`)

/// Tap opens the host app into Study scoped to "My Words" (`b2beruf://mywords/study`).
private struct FlashCardsLockEntry: TimelineEntry {
    let date: Date
}

private struct FlashCardsLockProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlashCardsLockEntry {
        FlashCardsLockEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (FlashCardsLockEntry) -> Void) {
        completion(FlashCardsLockEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlashCardsLockEntry>) -> Void) {
        let entry = FlashCardsLockEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

private struct FlashCardsLockWidgetView: View {
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 26, weight: .semibold))
                .widgetAccentable()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(localizedString("widget_flashcards_lock_accessibility_label")))
        .accessibilityHint(Text(localizedString("widget_flashcards_lock_accessibility_hint")))
        .widgetURL(QuickAddDeepLink.myWordsStudyURL)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private func localizedString(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", comment: "")
    }
}

struct FlashCardsLockWidget: Widget {
    let kind: String = "FlashCardsLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlashCardsLockProvider()) { _ in
            FlashCardsLockWidgetView()
        }
        .configurationDisplayName(localizedString("widget_flashcards_lock_display_name"))
        .description(localizedString("widget_flashcards_lock_description"))
        .supportedFamilies([.accessoryCircular])
    }

    private func localizedString(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", comment: "")
    }
}

#Preview(as: .accessoryCircular) {
    FlashCardsLockWidget()
} timeline: {
    FlashCardsLockEntry(date: .now)
}
