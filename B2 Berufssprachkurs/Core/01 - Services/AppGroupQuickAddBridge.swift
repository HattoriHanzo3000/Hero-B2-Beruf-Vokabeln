import Foundation
import OSLog

/// Drains quick-add URL stashed by `AddMyWordControlIntent` (App Group). Control + custom schemes are unreliable for `onOpenURL`.
enum AppGroupQuickAddBridge {
    private static let logger = Logger(subsystem: "com.gizatech.B2-Beruf.app", category: "AppGroupQuickAddBridge")
    private static let suiteName = QuickAddDeepLink.appGroupSuiteName
    private static let pendingURLKey = QuickAddDeepLink.appGroupPendingURLStringKey
    private static let markerFileName = QuickAddDeepLink.pendingQuickAddMarkerFileName
    private static let allowedSchemes: Set<String> = ["b2beruf", "heroapp"]

    static func consumePendingQuickAddIfNeeded() {
        var raw: String?

        if let defaults = UserDefaults(suiteName: suiteName) {
            if let s = defaults.string(forKey: pendingURLKey), !s.isEmpty {
                raw = s
            }
            defaults.removeObject(forKey: pendingURLKey)
        }

        if raw == nil || raw?.isEmpty == true {
            raw = readPendingMarkerFile()
        }

        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return }
        guard let scheme = url.scheme?.lowercased(), allowedSchemes.contains(scheme) else {
            logger.error("Ignoring quick-add URL with unsupported scheme: \(trimmed, privacy: .public)")
            return
        }

        DispatchQueue.main.async {
            AppDeepLinkRouter.shared.handle(url: url)
        }
    }

    private static func readPendingMarkerFile() -> String? {
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suiteName) else {
            return nil
        }
        let fileURL = dir.appendingPathComponent(markerFileName, isDirectory: false)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        defer {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                logger.error("Failed removing quick-add marker file: \(error.localizedDescription, privacy: .public)")
            }
        }
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            logger.error("Failed reading quick-add marker file: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
