//
//  WordOfTheDayResolver.swift
//  B2 Berufssprachkurs
//
//  Deterministic word-of-the-day from UserDefaults scope + periodicity (same keys as before).
//

import Foundation

enum WordOfTheDayResolver {
    private static let selectedSectionsKey = "wordOfTheDaySelectedSections"
    private static let periodicityKey = "wordOfTheDayPeriodicity"

    static func currentWord(from wordsBySection: [String: [Word]], defaults: UserDefaults = .standard) -> Word? {
        let csv = defaults.string(forKey: selectedSectionsKey) ?? ""
        let selectedSectionIds = WordOfTheDaySelectionPolicy.selectionSetFromCSV(csv)

        var eligibleWords: [Word] = []
        for (sectionId, words) in wordsBySection where selectedSectionIds.contains(sectionId) {
            eligibleWords.append(contentsOf: words)
        }
        guard !eligibleWords.isEmpty else { return nil }

        let periodicity = defaults.string(forKey: periodicityKey) ?? "24_hours"
        let hoursPerPeriod: Int = periodicity == "12_hours" ? 12 : 24

        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
        let hoursSinceStartOfYear = calendar.dateComponents([.hour], from: startOfYear, to: now).hour ?? 0
        let periodIndex = hoursSinceStartOfYear / hoursPerPeriod
        let wordIndex = periodIndex % eligibleWords.count
        return eligibleWords[wordIndex]
    }
}
