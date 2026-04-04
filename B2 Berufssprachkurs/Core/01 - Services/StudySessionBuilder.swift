//
//  StudySessionBuilder.swift
//  B2 Berufssprachkurs
//

import Foundation

enum StudySessionBuilder {
    static func prioritizeItems(_ items: [StudyItem], spacedRepetition: SpacedRepetitionService) -> [StudyItem] {
        let wordIds = items.map(\.wordId)
        let prioritizedIds = spacedRepetition.getPrioritizedCards(wordIds: wordIds, mode: .translations)

        var prioritizedItems: [StudyItem] = []
        var itemMap: [String: StudyItem] = [:]
        for item in items {
            itemMap[item.wordId] = item
        }

        for wordId in prioritizedIds {
            if let item = itemMap[wordId] {
                prioritizedItems.append(item)
                itemMap.removeValue(forKey: wordId)
            }
        }

        for item in itemMap.values {
            prioritizedItems.append(item)
        }

        return prioritizedItems
    }

    static func buildStudyItems(
        dataService: DataService,
        progressTranslationById: [String: String],
        filterBySectionId: String?,
        studyAllMode: Bool,
        favoritesOnly: Bool,
        categoryFilter: String?,
        isPremiumActive: Bool,
        spacedRepetition: SpacedRepetitionService
    ) -> [StudyItem] {
        var items: [StudyItem] = []

        var sectionsToProcess: [(section: Section, lection: Lection?)] = []

        if let sectionId = filterBySectionId {
            if sectionId == DataService.userMyWordsSectionId {
                if !dataService.userCustomWords.isEmpty {
                    sectionsToProcess.append((section: Section(id: sectionId, title: ""), lection: nil))
                }
            } else {
                for lection in dataService.lections {
                    if let section = lection.sections.first(where: { $0.id == sectionId }) {
                        if !isPremiumActive,
                           !DataService.GeneralWordsFreeTier.isLectionUnlockedWithoutPremium(lection.id) {
                            break
                        }
                        sectionsToProcess.append((section: section, lection: lection))
                        break
                    }
                }
                if sectionsToProcess.isEmpty && sectionId.hasPrefix("VERBEN_") {
                    if !isPremiumActive,
                       !DataService.VerbenFreeTier.isVerbenSectionUnlockedWithoutPremium(sectionId) {
                        // Free tier: only **an** is reachable from UI; block other VERBEN deep links.
                    } else if let words = dataService.wordsBySection[sectionId], !words.isEmpty {
                        let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: "VERBEN_", with: ""))
                        sectionsToProcess.append((section: section, lection: nil))
                    }
                }
                if sectionsToProcess.isEmpty && sectionId.hasPrefix("ADJEKTIVE_") {
                    if !isPremiumActive,
                       !DataService.AdjektiveFreeTier.isAdjektiveSectionUnlockedWithoutPremium(sectionId) {
                        // Free tier: only **an** is reachable from UI; block other ADJEKTIVE deep links.
                    } else if let words = dataService.wordsBySection[sectionId], !words.isEmpty {
                        let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: "ADJEKTIVE_", with: ""))
                        sectionsToProcess.append((section: section, lection: nil))
                    }
                }
            }
        } else {
            if let categoryFilter = categoryFilter {
                if categoryFilter == "VERBEN_" || categoryFilter == "ADJEKTIVE_" {
                    for (sectionId, words) in dataService.wordsBySection where sectionId.hasPrefix(categoryFilter) {
                        if categoryFilter == "VERBEN_",
                           !isPremiumActive,
                           !DataService.VerbenFreeTier.isVerbenSectionUnlockedWithoutPremium(sectionId) {
                            continue
                        }
                        if categoryFilter == "ADJEKTIVE_",
                           !isPremiumActive,
                           !DataService.AdjektiveFreeTier.isAdjektiveSectionUnlockedWithoutPremium(sectionId) {
                            continue
                        }
                        if !words.isEmpty {
                            let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: categoryFilter, with: ""))
                            sectionsToProcess.append((section: section, lection: nil))
                        }
                    }
                }
            } else if favoritesOnly {
                for lection in dataService.lections {
                    if !isPremiumActive,
                       !DataService.GeneralWordsFreeTier.isLectionUnlockedWithoutPremium(lection.id) {
                        continue
                    }
                    for section in lection.sections {
                        sectionsToProcess.append((section: section, lection: lection))
                    }
                }
                for (sectionId, words) in dataService.wordsBySection where sectionId.hasPrefix("VERBEN_") {
                    if !isPremiumActive,
                       !DataService.VerbenFreeTier.isVerbenSectionUnlockedWithoutPremium(sectionId) {
                        continue
                    }
                    if !words.isEmpty {
                        let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: "VERBEN_", with: ""))
                        sectionsToProcess.append((section: section, lection: nil))
                    }
                }
                for (sectionId, words) in dataService.wordsBySection where sectionId.hasPrefix("ADJEKTIVE_") {
                    if !isPremiumActive,
                       !DataService.AdjektiveFreeTier.isAdjektiveSectionUnlockedWithoutPremium(sectionId) {
                        continue
                    }
                    if !words.isEmpty {
                        let section = Section(id: sectionId, title: sectionId.replacingOccurrences(of: "ADJEKTIVE_", with: ""))
                        sectionsToProcess.append((section: section, lection: nil))
                    }
                }
                if !dataService.userCustomWords.isEmpty {
                    sectionsToProcess.append((
                        section: Section(id: DataService.userMyWordsSectionId, title: ""),
                        lection: nil
                    ))
                }
            } else {
                for lection in dataService.lections {
                    if !isPremiumActive,
                       !DataService.GeneralWordsFreeTier.isLectionUnlockedWithoutPremium(lection.id) {
                        continue
                    }
                    for section in lection.sections {
                        sectionsToProcess.append((section: section, lection: lection))
                    }
                }
            }
        }

        for (section, lection) in sectionsToProcess {
            let allWords = dataService.getWords(for: section.id)

            let wordsToProcess: [Word]
            if favoritesOnly {
                wordsToProcess = allWords.filter { dataService.isFavorite(wordId: $0.id) }
            } else if studyAllMode {
                wordsToProcess = allWords
            } else if filterBySectionId == nil {
                let isSectionCompleted = dataService.isSectionCompleted(sectionId: section.id)
                let isLectionCompleted = lection != nil ? dataService.isLectionCompleted(lectionId: lection!.id) : false

                if isSectionCompleted || isLectionCompleted {
                    wordsToProcess = allWords
                } else {
                    let checkedWordIds = dataService.checkedWords[section.id] ?? Set<String>()
                    wordsToProcess = allWords.filter { checkedWordIds.contains($0.id) }
                }
            } else {
                let checkedWordIds = dataService.checkedWords[section.id] ?? Set<String>()
                wordsToProcess = allWords.filter { checkedWordIds.contains($0.id) }
            }

            let isVerbenSection = section.id.hasPrefix("VERBEN_")
            let isAdjektiveSection = section.id.hasPrefix("ADJEKTIVE_")

            for word in wordsToProcess {
                if isVerbenSection {
                    let hasQuizAndExample = word.quiz?.isEmpty == false && word.example?.isEmpty == false
                    let explanationTrimmed = word.explanation?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let explanationOpt = (explanationTrimmed?.isEmpty == false) ? word.explanation : nil
                    let hasExample = word.example?.isEmpty == false
                    let translation = translationForStudy(for: word, progressTranslationById: progressTranslationById)
                    let hasTranslation = translation != nil
                    let hasVerbenStudyContent = hasQuizAndExample || hasTranslation || hasExample || explanationOpt != nil

                    if hasVerbenStudyContent {
                        items.append(StudyItem(
                            wordId: word.id,
                            sectionId: section.id,
                            germanWord: word.german,
                            synonym: nil,
                            explanation: explanationOpt,
                            translation: translation,
                            quiz: word.quiz,
                            example: word.example,
                            isVerbenSection: true
                        ))
                    }
                } else if isAdjektiveSection {
                    let synonym = word.synonyms?.first
                    let explanation = word.explanation?.isEmpty == false ? word.explanation : nil
                    let translation = translationForStudy(for: word, progressTranslationById: progressTranslationById)
                    let example = word.example?.isEmpty == false ? word.example : nil

                    if synonym != nil || explanation != nil || translation != nil || example != nil {
                        items.append(StudyItem(
                            wordId: word.id,
                            sectionId: section.id,
                            germanWord: word.german,
                            synonym: synonym,
                            explanation: explanation,
                            translation: translation,
                            quiz: nil,
                            example: example,
                            isVerbenSection: false
                        ))
                    }
                } else {
                    let synonym = word.synonyms?.first
                    let explanation = word.explanation?.isEmpty == false ? word.explanation : nil
                    let translation = translationForStudy(for: word, progressTranslationById: progressTranslationById)
                    let example = word.example?.isEmpty == false ? word.example : nil
                    let isMyWordsSection = section.id == DataService.userMyWordsSectionId
                    let hasGerman = !word.german.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                    let includeMyWordGermanOnly = isMyWordsSection && hasGerman
                    if synonym != nil || explanation != nil || translation != nil || includeMyWordGermanOnly {
                        items.append(StudyItem(
                            wordId: word.id,
                            sectionId: section.id,
                            germanWord: word.german,
                            synonym: synonym,
                            explanation: explanation,
                            translation: translation,
                            quiz: nil,
                            example: example,
                            isVerbenSection: false
                        ))
                    }
                }
            }
        }

        return prioritizeItems(items, spacedRepetition: spacedRepetition)
    }

    private static func translationForStudy(for word: Word, progressTranslationById: [String: String]) -> String? {
        if let raw = progressTranslationById[word.id] {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return raw }
        }
        let legacy = word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
        return legacy.isEmpty ? nil : word.translation
    }
}
