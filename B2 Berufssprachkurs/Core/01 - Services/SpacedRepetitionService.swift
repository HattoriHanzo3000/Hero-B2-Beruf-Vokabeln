//
//  SpacedRepetitionService.swift
//  B2 Berufssprachkurs
//
//  Core spaced-repetition engine for scheduling and review updates.
//  Created: 19.11.25.
//

import Foundation
import SwiftData

/// Spaced repetition using an SM-2–style rule set; one scheduling record per word.
@MainActor
final class SpacedRepetitionService {
    static let shared = SpacedRepetitionService()

    let userDefaults = UserDefaults.standard
    let studyDataKey = "spacedRepetitionStudyData"
    /// One-shot snapshot taken before the first debug progress preset is applied; restored from About → Debug “Regular mode”.
    let debugStudyDataBackupKey = "spacedRepetitionStudyDataDebugBackup"

    /// In-memory cache (source of truth in-session; persisted to SwiftData when bound). Keys are `wordId`.
    var studyDataCache: [String: StudyCardData] = [:]

    /// Set by ``bind(modelContext:)``; readable from extensions (e.g. debug presets).
    private(set) var modelContext: ModelContext?

    private init() {}

    // MARK: - Data Model

    struct StudyCardData: Codable {
        var easeFactor: Double
        var interval: Int
        var repetitions: Int
        var lastReviewDate: Date?
        var nextReviewDate: Date?

        init() {
            easeFactor = 2.5
            interval = 0
            repetitions = 0
            lastReviewDate = nil
            nextReviewDate = nil
        }
    }

    // MARK: - Public API

    /// Call once when the shared SwiftData stack is available (e.g. ``MainView.onAppear``).
    func bind(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadFromSwiftData()
    }

    func getStudyData(wordId: String) -> StudyCardData {
        studyDataCache[wordId] ?? StudyCardData()
    }

    /// - Parameter quality: 0–5 (0 = blackout, 5 = perfect).
    func recordStudyResult(wordId: String, quality: Int) {
        var data = studyDataCache[wordId] ?? StudyCardData()

        if quality >= 3 {
            if data.repetitions == 0 {
                data.interval = 1
            } else if data.repetitions == 1 {
                data.interval = 6
            } else {
                data.interval = Int(Double(data.interval) * data.easeFactor)
            }
            data.repetitions += 1

            data.easeFactor = data.easeFactor + (0.1 - (5.0 - Double(quality)) * (0.08 + (5.0 - Double(quality)) * 0.02))
            if data.easeFactor < 1.3 {
                data.easeFactor = 1.3
            }
        } else {
            data.repetitions = 0
            data.interval = 0
            data.easeFactor = max(1.3, data.easeFactor - 0.2)
        }

        let now = Date()
        data.lastReviewDate = now
        data.nextReviewDate = Calendar.current.date(byAdding: .day, value: data.interval, to: now)

        studyDataCache[wordId] = data
        persistRecord(wordId: wordId, data: data)
    }

    func isDue(wordId: String) -> Bool {
        let data = getStudyData(wordId: wordId)
        guard let nextReviewDate = data.nextReviewDate else {
            return true
        }
        return nextReviewDate <= Date()
    }

    func getDueCards(wordIds: [String]) -> [String] {
        wordIds.filter { isDue(wordId: $0) }
    }

    func getDueCount(wordIds: [String]) -> Int {
        getDueCards(wordIds: wordIds).count
    }

    /// Due cards first; then by next review date (earlier first). New cards (`nextReviewDate == nil`) sort as most urgent.
    func getPrioritizedCards(wordIds: [String]) -> [String] {
        let now = Date()
        return wordIds.sorted { id1, id2 in
            let d1 = getStudyData(wordId: id1)
            let d2 = getStudyData(wordId: id2)

            let due1: Bool
            if let n = d1.nextReviewDate {
                due1 = n <= now
            } else {
                due1 = true
            }
            let due2: Bool
            if let n = d2.nextReviewDate {
                due2 = n <= now
            } else {
                due2 = true
            }

            if due1 != due2 {
                return due1
            }

            let t1 = d1.nextReviewDate ?? .distantPast
            let t2 = d2.nextReviewDate ?? .distantPast
            return t1 < t2
        }
    }

    func resetAllStudyData() {
        studyDataCache.removeAll()
        userDefaults.removeObject(forKey: studyDataKey)
        userDefaults.removeObject(forKey: debugStudyDataBackupKey)
        if let context = modelContext {
            try? SpacedRepetitionRecord.deleteAll(in: context)
        }
    }

    func resetStudyData(wordId: String) {
        studyDataCache.removeValue(forKey: wordId)
        deleteRecord(wordId: wordId)
    }

    /// Normalizes legacy per-mode cache keys (`wordId_translations`, etc.) into one entry per `wordId`.
    func normalizeLegacyCacheKeys(_ cache: [String: StudyCardData]) -> [String: StudyCardData] {
        var grouped: [String: [(mode: String?, card: StudyCardData)]] = [:]
        for (key, card) in cache where !key.hasSuffix("_example") {
            guard let (wordId, mode) = MigrationManager.legacyWordIdAndMode(from: key) else { continue }
            grouped[wordId, default: []].append((mode: mode, card: card))
        }

        var normalized: [String: StudyCardData] = [:]
        for (wordId, entries) in grouped {
            if let translations = entries.first(where: { $0.mode == "translations" }) {
                normalized[wordId] = translations.card
            } else {
                normalized[wordId] = entries.max(by: { $0.card.repetitions < $1.card.repetitions })!.card
            }
        }
        return normalized
    }

    /// Full cache sync (debug presets, restore backup).
    func saveStudyData() {
        if let context = modelContext {
            replaceAllRecordsInSwiftData(from: studyDataCache, context: context)
        } else if let encoded = try? JSONEncoder().encode(studyDataCache) {
            userDefaults.set(encoded, forKey: studyDataKey)
        }
        NotificationCenter.default.post(name: .spacedRepetitionUpdated, object: nil)
    }

    /// Flushes pending SwiftData changes. Call at end of study sessions or when leaving the foreground.
    func saveChanges() {
        try? modelContext?.save()
    }

    // MARK: - SwiftData

    private func loadFromSwiftData() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<SpacedRepetitionRecord>()
        guard let rows = try? context.fetch(descriptor) else {
            studyDataCache = [:]
            return
        }
        studyDataCache.removeAll()
        for row in rows {
            var d = StudyCardData()
            d.easeFactor = row.easeFactor
            d.interval = row.interval
            d.repetitions = row.repetitions
            d.lastReviewDate = row.lastReviewDate
            d.nextReviewDate = row.nextReviewDate
            studyDataCache[row.wordId] = d
        }
    }

    private func persistRecord(wordId: String, data: StudyCardData) {
        guard let context = modelContext else {
            saveStudyData()
            return
        }
        let wid = wordId
        var descriptor = FetchDescriptor<SpacedRepetitionRecord>(
            predicate: #Predicate<SpacedRepetitionRecord> { $0.wordId == wid }
        )
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            existing.easeFactor = data.easeFactor
            existing.interval = data.interval
            existing.repetitions = data.repetitions
            existing.lastReviewDate = data.lastReviewDate
            existing.nextReviewDate = data.nextReviewDate
        } else {
            context.insert(SpacedRepetitionRecord(
                wordId: wordId,
                easeFactor: data.easeFactor,
                interval: data.interval,
                repetitions: data.repetitions,
                lastReviewDate: data.lastReviewDate,
                nextReviewDate: data.nextReviewDate
            ))
        }
        NotificationCenter.default.post(name: .spacedRepetitionUpdated, object: nil)
    }

    private func deleteRecord(wordId: String) {
        guard let context = modelContext else {
            saveStudyData()
            return
        }
        let wid = wordId
        var descriptor = FetchDescriptor<SpacedRepetitionRecord>(
            predicate: #Predicate<SpacedRepetitionRecord> { $0.wordId == wid }
        )
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        }
        NotificationCenter.default.post(name: .spacedRepetitionUpdated, object: nil)
    }

    private func replaceAllRecordsInSwiftData(from cache: [String: StudyCardData], context: ModelContext) {
        let normalized = normalizeLegacyCacheKeys(cache)
        try? SpacedRepetitionRecord.deleteAll(in: context)
        for (wordId, data) in normalized {
            let row = SpacedRepetitionRecord(
                wordId: wordId,
                easeFactor: data.easeFactor,
                interval: data.interval,
                repetitions: data.repetitions,
                lastReviewDate: data.lastReviewDate,
                nextReviewDate: data.nextReviewDate
            )
            context.insert(row)
        }
        saveChanges()
    }
}
