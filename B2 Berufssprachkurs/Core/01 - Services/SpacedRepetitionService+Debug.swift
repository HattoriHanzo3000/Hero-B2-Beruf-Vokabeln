//
//  SpacedRepetitionService+Debug.swift
//  B2 Berufssprachkurs
//
//  Debug helpers and diagnostics for spaced-repetition data.
//  Created: 05.04.26.
//

import Foundation

// MARK: - SpacedRepetitionService

extension SpacedRepetitionService {
    enum DebugProgressPreset: String, CaseIterable, Identifiable {
        case p25
        case p44
        case p67
        case p84
        case p93

        var id: String { rawValue }

        var targetPercentage: Int {
            switch self {
            case .p25: return 25
            case .p44: return 44
            case .p67: return 67
            case .p84: return 84
            case .p93: return 93
            }
        }

        /// Order: wrong, familiar, reinforced, mastered
        var ratios: (Double, Double, Double, Double) {
            switch self {
            case .p25:
                return (0.53, 0.27, 0.12, 0.08)
            case .p44:
                return (0.29, 0.30, 0.21, 0.20)
            case .p67:
                return (0.13, 0.17, 0.26, 0.44)
            case .p84:
                // Keep wrong low while preserving visible familiar/reinforced arcs.
                return (0.03, 0.09, 0.23, 0.65)
            case .p93:
                return (0.04, 0.02, 0.05, 0.89)
            }
        }
    }

    func previewStatistics(for preset: DebugProgressPreset, allWordIds: [String]) -> (wrong: Int, familiar: Int, reinforced: Int, mastered: Int, total: Int, readinessPercentage: Int) {
        let total = allWordIds.count
        guard total > 0 else { return (0, 0, 0, 0, 0, 0) }

        let (wrongRatio, familiarRatio, reinforcedRatio, masteredRatio) = preset.ratios
        let counts = distributeCounts(
            total: total,
            ratios: [wrongRatio, familiarRatio, reinforcedRatio, masteredRatio]
        )
        let wrong = counts[0]
        let familiar = counts[1]
        let reinforced = counts[2]
        let mastered = counts[3]

        let totalPoints = familiar * 1 + reinforced * 2 + mastered * 3
        let maxPossiblePoints = total * 3
        let readinessPercentage: Int
        if maxPossiblePoints > 0 {
            readinessPercentage = min(Int((Double(totalPoints) / Double(maxPossiblePoints)) * 100), 100)
        } else {
            readinessPercentage = 0
        }

        return (wrong, familiar, reinforced, mastered, total, readinessPercentage)
    }

    func applyDebugProgressPreset(_ preset: DebugProgressPreset, allWordIds: [String]) -> Int {
        guard !allWordIds.isEmpty else { return 0 }

        preserveStudyDataBeforeFirstDebugPresetIfNeeded()
        resetAllStudyDataPreservingDebugBackup()

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
            let repetitions = [3, 4, 5][idx % 3]
            writeDebugData(wordId: wordId, repetitions: repetitions, seed: idx + 3000)
        }

        saveStudyData()
        return getReadinessPercentage(allWordIds: allWordIds)
    }

    @discardableResult
    func restoreStudyDataFromBeforeDebugPresets() -> Bool {
        if let backup = userDefaults.data(forKey: debugStudyDataBackupKey),
           let decoded = try? JSONDecoder().decode([String: StudyCardData].self, from: backup) {
            studyDataCache = normalizeLegacyCacheKeys(decoded)
            userDefaults.removeObject(forKey: debugStudyDataBackupKey)
            userDefaults.removeObject(forKey: studyDataKey)
            saveStudyData()
            return true
        } else {
            studyDataCache.removeAll()
            userDefaults.removeObject(forKey: studyDataKey)
            saveStudyData()
            return false
        }
    }

    private func preserveStudyDataBeforeFirstDebugPresetIfNeeded() {
        guard userDefaults.data(forKey: debugStudyDataBackupKey) == nil else { return }
        if let encoded = try? JSONEncoder().encode(studyDataCache), !studyDataCache.isEmpty {
            userDefaults.set(encoded, forKey: debugStudyDataBackupKey)
        } else if let data = userDefaults.data(forKey: studyDataKey) {
            userDefaults.set(data, forKey: debugStudyDataBackupKey)
        } else {
            let empty: [String: StudyCardData] = [:]
            guard let encoded = try? JSONEncoder().encode(empty) else { return }
            userDefaults.set(encoded, forKey: debugStudyDataBackupKey)
        }
    }

    private func resetAllStudyDataPreservingDebugBackup() {
        studyDataCache.removeAll()
        userDefaults.removeObject(forKey: studyDataKey)
        if let context = modelContext {
            try? SpacedRepetitionRecord.deleteAll(in: context)
        }
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
        var data = StudyCardData()
        data.repetitions = repetitions
        data.interval = repetitions == 0 ? 0 : (repetitions * 3 + (seed % 2))
        data.easeFactor = repetitions == 0 ? 1.6 : min(2.8, 2.2 + Double(seed % 5) * 0.1)

        let now = Date()
        data.lastReviewDate = Calendar.current.date(byAdding: .day, value: -(seed % 12), to: now)
        data.nextReviewDate = Calendar.current.date(byAdding: .day, value: max(0, data.interval), to: now)
        studyDataCache[wordId] = data
    }
}
