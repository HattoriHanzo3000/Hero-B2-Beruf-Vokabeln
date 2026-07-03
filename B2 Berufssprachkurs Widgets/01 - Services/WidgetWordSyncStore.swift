//
//  WidgetWordSyncStore.swift
//  B2 Berufssprachkurs
//
//  Legacy snapshot helper; timeline display uses `WidgetWotdTimelineBuilder`.
//  Created: 08.04.26.
//

import Foundation

enum WidgetWordSyncStore {
    static func loadEntry(now: Date = Date()) -> WordOfTheDayEntry? {
        guard FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: QuickAddDeepLink.appGroupSuiteName
        ) != nil else {
            return nil
        }
        let entry = WidgetWotdTimelineBuilder.entryForDisplay(now: now)
        return entry
    }
}
