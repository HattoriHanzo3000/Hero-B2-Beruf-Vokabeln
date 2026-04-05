//
//  DataService+VocabularyLookup.swift
//  B2 Berufssprachkurs
//
//  Section metadata and favorite grouping derived from bundled + user vocabulary.
//

import Foundation

extension DataService {
    func getLectionAndSection(for sectionId: String) -> (lectionTitle: String, sectionTitle: String, lectionNumber: String, sectionLetter: String)? {
        if sectionId.hasPrefix("VERBEN_") {
            let preposition = String(sectionId.dropFirst(7))
            return (lectionTitle: "Verben mit Präpositionen", sectionTitle: preposition, lectionNumber: "", sectionLetter: "")
        }

        if sectionId.hasPrefix("ADJEKTIVE_") {
            let preposition = String(sectionId.dropFirst(10))
            return (lectionTitle: "Adjektive mit Präpositionen", sectionTitle: preposition, lectionNumber: "", sectionLetter: "")
        }

        for lection in lections {
            if let section = lection.sections.first(where: { $0.id == sectionId }) {
                let lectionNumber = String(lection.id)
                let sectionLetter = sectionId.last?.uppercased() ?? ""
                return (lectionTitle: lection.title, sectionTitle: section.title, lectionNumber: lectionNumber, sectionLetter: sectionLetter)
            }
        }
        return nil
    }

    func getSectionId(for wordId: String) -> String? {
        if userCustomWords.contains(where: { $0.id == wordId }) {
            return Self.userMyWordsSectionId
        }
        for (sectionId, words) in wordsBySection {
            if words.contains(where: { $0.id == wordId }) {
                return sectionId
            }
        }
        return nil
    }

    func getGroupType(for sectionId: String) -> FavoriteGroupType {
        if sectionId == Self.userMyWordsSectionId {
            return .myWords
        }
        if sectionId.hasPrefix("VERBEN_") {
            return .verbs
        }
        if sectionId.hasPrefix("ADJEKTIVE_") {
            return .adjectives
        }
        return .generalWords
    }

    func getDominantGroupType(for favoriteWords: [Word]) -> FavoriteGroupType {
        var groupCounts: [FavoriteGroupType: Int] = [:]

        for word in favoriteWords {
            if let sectionId = getSectionId(for: word.id) {
                let groupType = getGroupType(for: sectionId)
                groupCounts[groupType, default: 0] += 1
            }
        }

        if let dominantGroup = groupCounts.max(by: { $0.value < $1.value })?.key {
            return dominantGroup
        }

        return .generalWords
    }
}
