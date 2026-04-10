import AppIntents
import Foundation
import OSLog

/// Must be compiled into **both** the widget extension and the main app target so the Control can open the host and App Intents metadata is registered on the app.
@available(iOS 18.0, *)
struct AddMyWordControlIntent: AppIntent {
    private static let logger = Logger(subsystem: "com.gizatech.B2-Beruf.widgets", category: "AddMyWordControlIntent")

    static var title: LocalizedStringResource = "intent_add_my_word_title"
    static var description = IntentDescription(LocalizedStringResource("intent_add_my_word_description"))
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        let suite = QuickAddDeepLink.appGroupSuiteName
        let urlString = QuickAddDeepLink.url.absoluteString
        let key = QuickAddDeepLink.appGroupPendingURLStringKey
        let markerName = QuickAddDeepLink.pendingQuickAddMarkerFileName

        if let defaults = UserDefaults(suiteName: suite) {
            defaults.set(urlString, forKey: key)
        } else {
            Self.logger.error("App Group UserDefaults unavailable for suite: \(suite, privacy: .public)")
        }

        if let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suite) {
            let fileURL = dir.appendingPathComponent(markerName, isDirectory: false)
            do {
                try urlString.write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                Self.logger.error("Failed to write quick-add marker file: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            Self.logger.error("App Group container unavailable for suite: \(suite, privacy: .public)")
        }

        return .result()
    }
}
