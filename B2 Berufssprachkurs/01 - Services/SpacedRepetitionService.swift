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
    
    // MARK: - Private Helpers
    
    private func makeKey(wordId: String, mode: StudyMode) -> String {
        return "\(wordId)_\(modeKey(mode))"
    }
    
    private func modeKey(_ mode: StudyMode) -> String {
        switch mode {
        case .synonyms: return "synonyms"
        case .explanation: return "explanation"
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
    }
}

