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
    static let selectedSectionsKey = "wordOfTheDaySelectedSections"
    static let periodicityKey = "wordOfTheDayPeriodicity"

    static func currentWord(
        from wordsBySection: [String: [Word]],
        at date: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Word? {
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
        let hoursPerPeriod = hoursPerPeriod(from: periodicity)
        let calendar = Calendar.current
        let periodIndex = periodIndex(for: date, calendar: calendar, hoursPerPeriod: hoursPerPeriod)
        let currentYear = calendar.component(.year, from: date)
        let seedMaterial = [
            selectedSectionIds.sorted().joined(separator: ","),
            String(hoursPerPeriod),
            String(currentYear),
            String(periodIndex)
        ].joined(separator: "|")
        let randomIndex = Int(fnv1a64(seedMaterial) % UInt64(eligibleWords.count))
        return eligibleWords[randomIndex]
    }

    static func hoursPerPeriod(from periodicity: String) -> Int {
        periodicity == "12_hours" ? 12 : 24
    }

    /// Number of future timeline entries to precompute (~two weeks of coverage).
    static func timelineLookaheadPeriodCount(hoursPerPeriod: Int) -> Int {
        hoursPerPeriod == 12 ? 28 : 14
    }

    static func periodIndex(
        for date: Date,
        calendar: Calendar = .current,
        hoursPerPeriod: Int
    ) -> Int {
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: date)) ?? date
        let hoursSinceStartOfYear = calendar.dateComponents([.hour], from: startOfYear, to: date).hour ?? 0
        return hoursSinceStartOfYear / hoursPerPeriod
    }

    static func periodStartDate(
        periodIndex: Int,
        year: Int,
        hoursPerPeriod: Int,
        calendar: Calendar = .current
    ) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        guard let startOfYear = calendar.date(from: components) else { return nil }
        return calendar.date(byAdding: .hour, value: periodIndex * hoursPerPeriod, to: startOfYear)
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
