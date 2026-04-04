//
//  WordOfTheDaySelectionPolicy.swift
//  B2 Berufssprachkurs
//
//  Free-tier allowed WOTD source sections and CSV sanitization for subscription changes.
//

import Foundation

enum WordOfTheDaySelectionPolicy {
    /// Sections available in the free plan (comma-separated IDs in App Storage).
    static let freeTierAllowedSectionIDs: Set<String> = ["1A", "1B", "1C", "1D", "1E"]

    /// Intersects the current selection with free-tier rows; optionally restores default `1A` if empty.
    static func sanitizedCSVForFreeTier(_ csv: String, applyDefaultIfEmpty: Bool) -> String {
        let currentSelection = Set(csv.split(separator: ",").map(String.init))
        var sanitized = currentSelection.intersection(freeTierAllowedSectionIDs)
        if applyDefaultIfEmpty && sanitized.isEmpty {
            sanitized = ["1A"]
        }
        return sanitized.sorted().joined(separator: ",")
    }

    /// Count of selected sections; empty CSV is treated as default `1A` (count 1).
    static func selectedSectionCount(csv: String) -> Int {
        if csv.isEmpty { return 1 }
        return csv.split(separator: ",").count
    }
}
