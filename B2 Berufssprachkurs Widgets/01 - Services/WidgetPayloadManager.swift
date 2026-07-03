//
//  WidgetPayloadManager.swift
//  B2 Berufssprachkurs
//
//  Manages the saving and loading of the pre-computed widget timeline.
//  Created: 03.07.26.
//

import Foundation

// Manages the saving and loading of the pre-computed widget timeline
public enum WidgetPayloadManager {
    private static let appGroupIdentifier = "group.com.gizatech.B2-Beruf"
    private static let payloadFileName = "widget_timeline_payload.json"

    private static var payloadFileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(payloadFileName)
    }

    // Called ONLY by the Main App
    public static func savePayload(entries: [WidgetTimelineEntryPayload]) {
        let payload = WidgetTimelinePayload(entries: entries, generatedAt: Date())
        guard let url = payloadFileURL else { return }

        do {
            let data = try JSONEncoder().encode(payload)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Payload Manager: Failed to save widget payload: \(error)")
        }
    }

    // Called ONLY by the Widget Extension
    public static func loadPayload() -> WidgetTimelinePayload? {
        guard let url = payloadFileURL,
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(WidgetTimelinePayload.self, from: data) else {
            return nil
        }
        return payload
    }
}
