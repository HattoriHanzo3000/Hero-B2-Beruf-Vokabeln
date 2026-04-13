//
//  WordOfTheDayResolver.swift
//  B2 Berufssprachkurs
//
//  Resolves the current Word of the Day from selected sources.
//  Created: 05.04.26.
//

import Foundation

// MARK: - WordOfTheDayResolver

enum WordOfTheDayResolver {
    private static let selectedSectionsKey = "wordOfTheDaySelectedSections"
    private static let periodicityKey = "wordOfTheDayPeriodicity"

    static func currentWord(from wordsBySection: [String: [Word]], defaults: UserDefaults = .standard) -> Word? {
        let csv = defaults.string(forKey: selectedSectionsKey) ?? ""
        let selectedSectionIds = WordOfTheDaySelectionPolicy.selectionSetFromCSV(csv)

        let orderedSelectedSectionIds = selectedSectionIds.sorted()
        var eligibleWords: [Word] = []
        for sectionId in orderedSelectedSectionIds {
            guard let words = wordsBySection[sectionId] else { continue }
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
        let currentYear = calendar.component(.year, from: now)
        let seedMaterial = [
            selectedSectionIds.sorted().joined(separator: ","),
            String(hoursPerPeriod),
            String(currentYear),
            String(periodIndex)
        ].joined(separator: "|")
        let randomIndex = Int(fnv1a64(seedMaterial) % UInt64(eligibleWords.count))
        let wordIndex = randomIndex
        return eligibleWords[wordIndex]
    }

    /// Stable non-cryptographic hash for deterministic "random" selection across process restarts.
    private static func fnv1a64(_ input: String) -> UInt64 {
        let offsetBasis: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211
        var hash = offsetBasis
        for byte in input.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }
}
