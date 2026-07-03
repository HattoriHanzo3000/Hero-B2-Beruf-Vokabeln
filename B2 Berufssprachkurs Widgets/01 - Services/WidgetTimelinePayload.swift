//
//  WidgetTimelinePayload.swift
//  B2 Berufssprachkurs
//
//  Lightweight DTO shared between the main app and widget extension.
//  Created: 03.07.26.
//

import Foundation

// A lightweight DTO containing only the data the widget needs to render
public struct WidgetTimelinePayload: Codable {
    public let entries: [WidgetTimelineEntryPayload]
    public let generatedAt: Date
}

public struct WidgetTimelineEntryPayload: Codable {
    public let date: Date
    public let word: String
    public let translation: String
    public let exampleSentence: String?
}
