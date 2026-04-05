//
//  SpacedRepetitionService+Statistics.swift
//  B2 Berufssprachkurs
//

import Foundation

extension SpacedRepetitionService {
    /// Progress buckets by word (max repetitions across modes).
    func getProgressByLevel(allWordIds: [String]) -> (wrong: Int, familiar: Int, reinforced: Int, mastered: Int, total: Int) {
        var wrong = 0
        var familiar = 0
        var reinforced = 0
        var mastered = 0

        var wordMaxRepetitions: [String: Int] = [:]

        for wordId in allWordIds {
            var maxRepetitions = 0
            var hasBeenReviewed = false

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

        for (_, repetitions) in wordMaxRepetitions {
            switch repetitions {
            case 0:
                wrong += 1
            case 1:
                familiar += 1
            case 2:
                reinforced += 1
            default:
                mastered += 1
            }
        }

        let total = allWordIds.count
        return (wrong, familiar, reinforced, mastered, total)
    }

    func getReadinessPercentage(allWordIds: [String]) -> Int {
        guard !allWordIds.isEmpty else { return 0 }

        let progress = getProgressByLevel(allWordIds: allWordIds)

        let totalPoints = progress.familiar * 1 + progress.reinforced * 2 + progress.mastered * 3
        let maxPossiblePoints = progress.total * 3

        guard maxPossiblePoints > 0 else { return 0 }

        let percentage = Int((Double(totalPoints) / Double(maxPossiblePoints)) * 100)
        return min(percentage, 100)
    }
}
