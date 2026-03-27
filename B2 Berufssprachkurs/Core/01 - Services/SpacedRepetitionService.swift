//
//  SpacedRepetitionService.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import Foundation

/// Spaced Repetition Service using SM-2 algorithm
/// Tracks study progress for each word in each study mode
@MainActor
class SpacedRepetitionService {
    static let shared = SpacedRepetitionService()
    
    private let userDefaults = UserDefaults.standard
    private let studyDataKey = "spacedRepetitionStudyData"
    
    // In-memory cache for performance
    private var studyDataCache: [String: StudyCardData] = [:]
    
    private init() {
        loadStudyData()
    }
    
    // MARK: - Data Model
    
    struct StudyCardData: Codable {
        var easeFactor: Double      // Current ease factor (default: 2.5)
        var interval: Int           // Days until next review (default: 0)
        var repetitions: Int        // Number of successful reviews (default: 0)
        var lastReviewDate: Date?   // Last time this card was reviewed
        var nextReviewDate: Date?   // When this card is due for review
        
        init() {
            self.easeFactor = 2.5
            self.interval = 0
            self.repetitions = 0
            self.lastReviewDate = nil
            self.nextReviewDate = nil
        }
    }
    
    // MARK: - Public API
    
    /// Get study data for a specific word and mode
    func getStudyData(wordId: String, mode: StudyMode) -> StudyCardData {
        let key = makeKey(wordId: wordId, mode: mode)
        return studyDataCache[key] ?? StudyCardData()
    }
    
    /// Record a study session result
    /// - Parameters:
    ///   - wordId: The word being studied
    ///   - mode: The study mode (synonyms, explanation, translations)
    ///   - quality: 0-5 quality rating (0=complete blackout, 5=perfect response)
    func recordStudyResult(wordId: String, mode: StudyMode, quality: Int) {
        let key = makeKey(wordId: wordId, mode: mode)
        var data = studyDataCache[key] ?? StudyCardData()
        
        // SM-2 Algorithm
        if quality >= 3 {
            // Correct response
            if data.repetitions == 0 {
                data.interval = 1
            } else if data.repetitions == 1 {
                data.interval = 6
            } else {
                data.interval = Int(Double(data.interval) * data.easeFactor)
            }
            data.repetitions += 1
            
            // Update ease factor
            data.easeFactor = data.easeFactor + (0.1 - (5.0 - Double(quality)) * (0.08 + (5.0 - Double(quality)) * 0.02))
            if data.easeFactor < 1.3 {
                data.easeFactor = 1.3 // Minimum ease factor
            }
        } else {
            // Incorrect response - reset
            data.repetitions = 0
            data.interval = 0
            // Slightly decrease ease factor for wrong answers
            data.easeFactor = max(1.3, data.easeFactor - 0.2)
        }
        
        // Update dates
        let now = Date()
        data.lastReviewDate = now
        data.nextReviewDate = Calendar.current.date(byAdding: .day, value: data.interval, to: now)
        
        studyDataCache[key] = data
        saveStudyData()
    }
    
    /// Check if a card is due for review
    func isDue(wordId: String, mode: StudyMode) -> Bool {
        let data = getStudyData(wordId: wordId, mode: mode)
        
        // New cards are always due
        guard let nextReviewDate = data.nextReviewDate else {
            return true
        }
        
        // Card is due if next review date has passed
        return nextReviewDate <= Date()
    }
    
    /// Get all due cards for a study mode
    func getDueCards(wordIds: [String], mode: StudyMode) -> [String] {
        return wordIds.filter { isDue(wordId: $0, mode: mode) }
    }
    
    /// Get count of due cards
    func getDueCount(wordIds: [String], mode: StudyMode) -> Int {
        return getDueCards(wordIds: wordIds, mode: mode).count
    }
    
    /// Get cards sorted by priority (due cards first, then by next review date)
    func getPrioritizedCards(wordIds: [String], mode: StudyMode) -> [String] {
        let now = Date()
        
        return wordIds.sorted { wordId1, wordId2 in
            let data1 = getStudyData(wordId: wordId1, mode: mode)
            let data2 = getStudyData(wordId: wordId2, mode: mode)
            
            // Due cards come first
            let isDue1 = data1.nextReviewDate == nil || data1.nextReviewDate! <= now
            let isDue2 = data2.nextReviewDate == nil || data2.nextReviewDate! <= now
            
            if isDue1 != isDue2 {
                return isDue1 // Due cards first
            }
            
            // Among due cards, prioritize by next review date (earlier = higher priority)
            // Among non-due cards, prioritize by next review date (earlier = higher priority)
            guard let date1 = data1.nextReviewDate, let date2 = data2.nextReviewDate else {
                return isDue1 // If one has no date, it's due
            }
            
            return date1 < date2
        }
    }
    
    /// Reset all study data (for testing or user reset)
    func resetAllStudyData() {
        studyDataCache.removeAll()
        userDefaults.removeObject(forKey: studyDataKey)
    }
    
    /// Reset study data for a specific word and mode
    func resetStudyData(wordId: String, mode: StudyMode) {
        let key = makeKey(wordId: wordId, mode: mode)
        studyDataCache.removeValue(forKey: key)
        saveStudyData()
    }

    // MARK: - Debug Presets

    enum DebugProgressPreset: String, CaseIterable, Identifiable {
        case p25
        case p44
        case p67
        case p93

        var id: String { rawValue }

        var targetPercentage: Int {
            switch self {
            case .p25: return 25
            case .p44: return 44
            case .p67: return 67
            case .p93: return 93
            }
        }

        /// Uneven, human-like category distributions.
        /// Order: wrong, familiar, reinforced, mastered
        var ratios: (Double, Double, Double, Double) {
            switch self {
            case .p25:
                return (0.53, 0.27, 0.12, 0.08)
            case .p44:
                return (0.29, 0.30, 0.21, 0.20)
            case .p67:
                return (0.13, 0.17, 0.26, 0.44)
            case .p93:
                return (0.04, 0.02, 0.05, 0.89)
            }
        }
    }

    /// Applies a debug progress state by writing spaced-repetition records directly.
    /// Returns resulting readiness percentage after writing.
    func applyDebugProgressPreset(_ preset: DebugProgressPreset, allWordIds: [String]) -> Int {
        guard !allWordIds.isEmpty else { return 0 }

        resetAllStudyData()

        let shuffledIds = allWordIds.shuffled()
        let (wrongRatio, familiarRatio, reinforcedRatio, masteredRatio) = preset.ratios
        let counts = distributeCounts(
            total: shuffledIds.count,
            ratios: [wrongRatio, familiarRatio, reinforcedRatio, masteredRatio]
        )

        let wrongCount = counts[0]
        let familiarCount = counts[1]
        let reinforcedCount = counts[2]
        let masteredCount = counts[3]

        var cursor = 0
        for idx in 0..<wrongCount {
            let wordId = shuffledIds[cursor]
            cursor += 1
            writeDebugData(wordId: wordId, repetitions: 0, seed: idx)
        }

        for idx in 0..<familiarCount {
            let wordId = shuffledIds[cursor]
            cursor += 1
            writeDebugData(wordId: wordId, repetitions: 1, seed: idx + 1000)
        }

        for idx in 0..<reinforcedCount {
            let wordId = shuffledIds[cursor]
            cursor += 1
            writeDebugData(wordId: wordId, repetitions: 2, seed: idx + 2000)
        }

        for idx in 0..<masteredCount {
            let wordId = shuffledIds[cursor]
            cursor += 1
            // Add slight variance to mastered depth.
            let repetitions = [3, 4, 5][idx % 3]
            writeDebugData(wordId: wordId, repetitions: repetitions, seed: idx + 3000)
        }

        saveStudyData()
        return getReadinessPercentage(allWordIds: allWordIds)
    }
    
    // MARK: - Progress Statistics
    
    /// Get progress statistics by level for all words across all modes
    /// - Parameter allWordIds: Array of all word IDs to calculate statistics for
    /// - Returns: Tuple with counts for wrong, familiar, reinforced, mastered, and total
    func getProgressByLevel(allWordIds: [String]) -> (wrong: Int, familiar: Int, reinforced: Int, mastered: Int, total: Int) {
        var wrong = 0
        var familiar = 0
        var reinforced = 0
        var mastered = 0
        
        // Count each word's highest achievement across all modes
        var wordMaxRepetitions: [String: Int] = [:]
        
        for wordId in allWordIds {
            var maxRepetitions = 0
            var hasBeenReviewed = false
            
            // Check all modes for this word
            for mode in [StudyMode.synonyms, StudyMode.explanation, StudyMode.translations, StudyMode.example] {
                let data = getStudyData(wordId: wordId, mode: mode)
                if data.lastReviewDate != nil {
                    hasBeenReviewed = true
                    maxRepetitions = max(maxRepetitions, data.repetitions)
                }
            }
            
            if hasBeenReviewed {
                wordMaxRepetitions[wordId] = maxRepetitions
            }
        }
        
        // Categorize words based on their maximum repetitions
        for (_, repetitions) in wordMaxRepetitions {
            switch repetitions {
            case 0:
                wrong += 1
            case 1:
                familiar += 1
            case 2:
                reinforced += 1
            default: // 3 or more
                mastered += 1
            }
        }
        
        let total = allWordIds.count
        return (wrong, familiar, reinforced, mastered, total)
    }
    
    /// Calculate readiness percentage based on progress
    /// - Parameter allWordIds: Array of all word IDs
    /// - Returns: Readiness percentage (0-100)
    func getReadinessPercentage(allWordIds: [String]) -> Int {
        guard !allWordIds.isEmpty else { return 0 }
        
        let progress = getProgressByLevel(allWordIds: allWordIds)
        
        // Weighted calculation: wrong=0, familiar=1, reinforced=2, mastered=3
        let totalPoints = progress.wrong * 0 + progress.familiar * 1 + progress.reinforced * 2 + progress.mastered * 3
        let maxPossiblePoints = progress.total * 3
        
        guard maxPossiblePoints > 0 else { return 0 }
        
        let percentage = Int((Double(totalPoints) / Double(maxPossiblePoints)) * 100)
        return min(percentage, 100)
    }
    
    // MARK: - Private Helpers
    
    private func makeKey(wordId: String, mode: StudyMode) -> String {
        return "\(wordId)_\(modeKey(mode))"
    }
    
    private func modeKey(_ mode: StudyMode) -> String {
        switch mode {
        case .synonyms: return "synonyms"
        case .explanation: return "explanation"
        case .example: return "example"
        case .translations: return "translations"
        }
    }
    
    private func loadStudyData() {
        guard let data = userDefaults.data(forKey: studyDataKey),
              let decoded = try? JSONDecoder().decode([String: StudyCardData].self, from: data) else {
            studyDataCache = [:]
            return
        }
        studyDataCache = decoded
    }
    
    private func saveStudyData() {
        guard let encoded = try? JSONEncoder().encode(studyDataCache) else {
            return
        }
        userDefaults.set(encoded, forKey: studyDataKey)
        
        // Notify that study data has been updated
        NotificationCenter.default.post(name: NSNotification.Name("SpacedRepetitionUpdated"), object: nil)
    }

    private func distributeCounts(total: Int, ratios: [Double]) -> [Int] {
        let raw = ratios.map { Double(total) * $0 }
        var counts = raw.map { Int($0.rounded(.down)) }
        var remainder = total - counts.reduce(0, +)

        if remainder > 0 {
            let fractions = raw.enumerated()
                .map { ($0.offset, $0.element - Double(counts[$0.offset])) }
                .sorted { lhs, rhs in lhs.1 > rhs.1 }

            var idx = 0
            while remainder > 0 {
                let target = fractions[idx % fractions.count].0
                counts[target] += 1
                remainder -= 1
                idx += 1
            }
        }

        return counts
    }

    private func writeDebugData(wordId: String, repetitions: Int, seed: Int) {
        let mode: StudyMode
        switch seed % 4 {
        case 0: mode = .translations
        case 1: mode = .synonyms
        case 2: mode = .explanation
        default: mode = .example
        }

        let key = makeKey(wordId: wordId, mode: mode)
        var data = StudyCardData()
        data.repetitions = repetitions
        data.interval = repetitions == 0 ? 0 : (repetitions * 3 + (seed % 2))
        data.easeFactor = repetitions == 0 ? 1.6 : min(2.8, 2.2 + Double(seed % 5) * 0.1)

        let now = Date()
        data.lastReviewDate = Calendar.current.date(byAdding: .day, value: -(seed % 12), to: now)
        data.nextReviewDate = Calendar.current.date(byAdding: .day, value: max(0, data.interval), to: now)
        studyDataCache[key] = data
    }
}

