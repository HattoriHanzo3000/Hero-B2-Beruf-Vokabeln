//
//  SpacedRepetitionService.swift
//  B2 Berufssprachkurs
//
//  SM-2 spaced repetition, persistence, and scheduling.
//

import Foundation
import SwiftData

/// Spaced repetition using an SM-2–style rule set; tracks study progress per word and ``StudyMode``.
@MainActor
final class SpacedRepetitionService {
    static let shared = SpacedRepetitionService()

    let userDefaults = UserDefaults.standard
    let studyDataKey = "spacedRepetitionStudyData"
    /// One-shot snapshot taken before the first debug progress preset is applied; restored from About → Debug “Regular mode”.
    let debugStudyDataBackupKey = "spacedRepetitionStudyDataDebugBackup"

    /// In-memory cache (source of truth in-session; persisted to SwiftData when bound).
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

    func getStudyData(wordId: String, mode: StudyMode) -> StudyCardData {
        let key = makeKey(wordId: wordId, mode: mode)
        return studyDataCache[key] ?? StudyCardData()
    }

    /// - Parameter quality: 0–5 (0 = blackout, 5 = perfect).
    func recordStudyResult(wordId: String, mode: StudyMode, quality: Int) {
        let key = makeKey(wordId: wordId, mode: mode)
        var data = studyDataCache[key] ?? StudyCardData()

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

        studyDataCache[key] = data
        persistRecord(wordId: wordId, mode: mode, data: data)
    }

    func isDue(wordId: String, mode: StudyMode) -> Bool {
        let data = getStudyData(wordId: wordId, mode: mode)
        guard let nextReviewDate = data.nextReviewDate else {
            return true
        }
        return nextReviewDate <= Date()
    }

    func getDueCards(wordIds: [String], mode: StudyMode) -> [String] {
        wordIds.filter { isDue(wordId: $0, mode: mode) }
    }

    func getDueCount(wordIds: [String], mode: StudyMode) -> Int {
        getDueCards(wordIds: wordIds, mode: mode).count
    }

    /// Due cards first; then by next review date (earlier first). New cards (`nextReviewDate == nil`) sort as most urgent.
    func getPrioritizedCards(wordIds: [String], mode: StudyMode) -> [String] {
        let now = Date()
        return wordIds.sorted { id1, id2 in
            let d1 = getStudyData(wordId: id1, mode: mode)
            let d2 = getStudyData(wordId: id2, mode: mode)

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

    func resetStudyData(wordId: String, mode: StudyMode) {
        let key = makeKey(wordId: wordId, mode: mode)
        studyDataCache.removeValue(forKey: key)
        deleteRecord(wordId: wordId, mode: mode)
    }

    // MARK: - Internal (extensions in other files)

    func makeKey(wordId: String, mode: StudyMode) -> String {
        "\(wordId)_\(modeKey(mode))"
    }

    func modeKey(_ mode: StudyMode) -> String {
        switch mode {
        case .synonyms: return "synonyms"
        case .explanation: return "explanation"
        case .translations: return "translations"
        }
    }

    /// Parses legacy cache keys: `\(wordId)_\(modeKey)`.
    static func parseStorageKey(_ key: String) -> (wordId: String, mode: StudyMode)? {
        for mode in StudyMode.allCases {
            let suffix = "_" + SpacedRepetitionService.modeKeyStatic(mode)
            guard key.hasSuffix(suffix) else { continue }
            let wordId = String(key.dropLast(suffix.count))
            return (wordId, mode)
        }
        return nil
    }

    private static func modeKeyStatic(_ mode: StudyMode) -> String {
        switch mode {
        case .synonyms: return "synonyms"
        case .explanation: return "explanation"
        case .translations: return "translations"
        }
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
            guard let mode = StudyMode(modeKey: row.studyModeRaw) else { continue }
            let key = makeKey(wordId: row.wordId, mode: mode)
            var d = StudyCardData()
            d.easeFactor = row.easeFactor
            d.interval = row.interval
            d.repetitions = row.repetitions
            d.lastReviewDate = row.lastReviewDate
            d.nextReviewDate = row.nextReviewDate
            studyDataCache[key] = d
        }
    }

    private func persistRecord(wordId: String, mode: StudyMode, data: StudyCardData) {
        guard let context = modelContext else {
            saveStudyData()
            return
        }
        let modeRaw = modeKey(mode)
        let wid = wordId
        var descriptor = FetchDescriptor<SpacedRepetitionRecord>(
            predicate: #Predicate<SpacedRepetitionRecord> { $0.wordId == wid && $0.studyModeRaw == modeRaw }
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
                studyModeRaw: modeRaw,
                easeFactor: data.easeFactor,
                interval: data.interval,
                repetitions: data.repetitions,
                lastReviewDate: data.lastReviewDate,
                nextReviewDate: data.nextReviewDate
            ))
        }
        try? context.save()
        NotificationCenter.default.post(name: .spacedRepetitionUpdated, object: nil)
    }

    private func deleteRecord(wordId: String, mode: StudyMode) {
        guard let context = modelContext else {
            saveStudyData()
            return
        }
        let modeRaw = modeKey(mode)
        let wid = wordId
        var descriptor = FetchDescriptor<SpacedRepetitionRecord>(
            predicate: #Predicate<SpacedRepetitionRecord> { $0.wordId == wid && $0.studyModeRaw == modeRaw }
        )
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
            try? context.save()
        }
        NotificationCenter.default.post(name: .spacedRepetitionUpdated, object: nil)
    }

    private func replaceAllRecordsInSwiftData(from cache: [String: StudyCardData], context: ModelContext) {
        try? SpacedRepetitionRecord.deleteAll(in: context)
        for (key, data) in cache {
            guard let (wordId, mode) = Self.parseStorageKey(key) else { continue }
            let row = SpacedRepetitionRecord(
                wordId: wordId,
                studyModeRaw: modeKey(mode),
                easeFactor: data.easeFactor,
                interval: data.interval,
                repetitions: data.repetitions,
                lastReviewDate: data.lastReviewDate,
                nextReviewDate: data.nextReviewDate
            )
            context.insert(row)
        }
        try? context.save()
    }
}
