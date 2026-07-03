//
//  QuickAddDeepLink.swift
//  B2 Berufssprachkurs
//
//  Shared deep links used by widgets/controls to open specific in-app destinations.
//  Created: 10.04.26.
//

import Foundation

/// Shared Quick Add URL for the Lock Screen widget (`.widgetURL`) and Control handoff. Routed in-app by `AppDeepLinkRouter` (`mywords/add` → resume + sheet / Pro alert).
enum QuickAddDeepLink {
    /// Lock Screen Control: open add composer.
    nonisolated static let url = makeURL("b2beruf://mywords/add")
    /// Lock Screen accessory widget: open learning session scoped to "My Words".
    nonisolated static let myWordsStudyURL = makeURL("b2beruf://mywords/study")
    /// Home-screen Word of the Day widget: foreground app without route mutation.
    nonisolated static let wordOfTheDayURL = makeURL("b2beruf://wotd")

    /// When `OpenURLIntent` does not fire for Controls, the intent stashes this for the main app (`AppGroupQuickAddBridge`).
    nonisolated static let appGroupSuiteName = "group.com.gizatech.B2-Beruf"
    nonisolated static let appGroupPendingURLStringKey = "com.gizatech.B2Beruf.pendingQuickAddURLString"
    /// Backup handoff if `UserDefaults` is slow across the extension boundary.
    nonisolated static let pendingQuickAddMarkerFileName = "pending-quick-add-url.txt"
    /// Shared storage key for the Word of the Day widget payload.
    nonisolated static let wordOfTheDayPayloadKey = "widget.wordOfTheDay.payload"
    /// App Group JSON file mapping word IDs to user translations for the widget.
    nonisolated static let wordOfTheDayTranslationsFileName = "widget.wotd.translations.json"
    /// WidgetKit kind for `WordOfTheDayWidget`.
    nonisolated static let wordOfTheDayWidgetKind = "WordOfTheDayWidget"

    private nonisolated static func makeURL(_ raw: String) -> URL {
        guard let url = URL(string: raw) else {
            preconditionFailure("Invalid deep link constant: \(raw)")
        }
        return url
    }
}
