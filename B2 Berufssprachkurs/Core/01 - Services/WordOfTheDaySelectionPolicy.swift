//
//  WordOfTheDaySelectionPolicy.swift
//  B2 Berufssprachkurs
//
//  Free-tier allowed WOTD source sections and CSV sanitization for subscription changes.
//

import Foundation

enum WordOfTheDaySelectionPolicy {
    /// Lection 1 subsection IDs available without premium (general words).
    static let freeTierAllowedSectionIDs: Set<String> = ["1A", "1B", "1C", "1D", "1E"]

    /// All source sections a free user may enable for Word of the Day (lection 1 A–E plus free Verben/Adjektive „an“ stacks).
    static var freeTierWotdSelectableSectionIDs: Set<String> {
        freeTierAllowedSectionIDs.union([
            VocabularyCatalog.VerbenFreeTier.unlockedSectionId,
            VocabularyCatalog.AdjektiveFreeTier.unlockedSectionId
        ])
    }

    /// Parses persisted CSV into a set. Empty string means “not set” → default `1A` only.
    static func selectionSetFromCSV(_ csv: String) -> Set<String> {
        if csv.isEmpty {
            return ["1A"]
        }
        return Set(csv.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) })
    }

    /// Stable serialization for App Storage / bindings.
    static func csvFromSelectionSet(_ ids: Set<String>) -> String {
        ids.sorted().joined(separator: ",")
    }

    /// Intersects with free-tier WOTD rows (keeps `VERBEN_an` / `ADJEKTIVE_an`; drops other stacks when downgrading).
    static func sanitizedSelectionSetForFreeTier(_ ids: Set<String>, applyDefaultIfEmpty: Bool) -> Set<String> {
        var sanitized = ids.intersection(freeTierWotdSelectableSectionIDs)
        if applyDefaultIfEmpty && sanitized.isEmpty {
            sanitized = ["1A"]
        }
        return sanitized
    }

    /// Intersects the current selection with free-tier rows; optionally restores default `1A` if empty.
    static func sanitizedCSVForFreeTier(_ csv: String, applyDefaultIfEmpty: Bool) -> String {
        let currentSelection = Set(csv.split(separator: ",").map(String.init))
        let sanitized = sanitizedSelectionSetForFreeTier(currentSelection, applyDefaultIfEmpty: applyDefaultIfEmpty)
        return csvFromSelectionSet(sanitized)
    }

    /// Count of selected sections; empty CSV is treated as default `1A` (count 1).
    static func selectedSectionCount(csv: String) -> Int {
        if csv.isEmpty { return 1 }
        return csv.split(separator: ",").count
    }

    /// Letter suffix from a section id (e.g. `1A` → `A`, `12B` → `B`).
    static func sectionLetter(fromSectionId sectionId: String) -> String {
        let letterPart = sectionId.replacingOccurrences(of: "^\\d+", with: "", options: .regularExpression)
        return letterPart.isEmpty ? sectionId : letterPart
    }
}
