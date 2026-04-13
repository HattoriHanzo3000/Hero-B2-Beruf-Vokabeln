//
//  VocabularySearchEngine.swift
//  B2 Berufssprachkurs
//
//  Search engine matching query terms against vocabulary content.
//  Created: 04.04.26.
//

import Foundation

// MARK: - VocabularySearchEngine

enum VocabularySearchEngine {
    private static let compareOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    static func matches(
        query: String,
        dataService: DataService,
        isPremium: Bool,
        userTranslation: (String) -> String
    ) -> [(sectionId: String, word: Word)] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        var matches: [(sectionId: String, word: Word)] = []
        matches.reserveCapacity(64)

        for (sectionId, words) in dataService.wordsBySection {
            guard dataService.isSectionIncludedInGlobalSearch(sectionId: sectionId, isPremium: isPremium) else { continue }
            for word in words {
                let ut = userTranslation(word.id)
                if wordMatches(query: q, word: word, userTranslation: ut) {
                    matches.append((sectionId, word))
                }
            }
        }

        for word in dataService.userCustomWords {
            let ut = userTranslation(word.id)
            if wordMatches(query: q, word: word, userTranslation: ut) {
                matches.append((DataService.userMyWordsSectionId, word))
            }
        }

        return matches.sorted { lhs, rhs in
            let o0 = rank(word: lhs.word, query: q)
            let o1 = rank(word: rhs.word, query: q)
            if o0 != o1 { return o0 < o1 }
            if lhs.word.german != rhs.word.german {
                return lhs.word.german.localizedCaseInsensitiveCompare(rhs.word.german) == .orderedAscending
            }
            return lhs.sectionId < rhs.sectionId
        }
    }

    /// Short-circuits on first hit; avoids building a full “haystack” array per word.
    private static func wordMatches(query: String, word: Word, userTranslation: String) -> Bool {
        if textMatches(word.german, query: query) { return true }
        if textMatches(userTranslation, query: query) { return true }
        if textMatches(word.translation, query: query) { return true }
        if let s = word.explanation, textMatches(s, query: query) { return true }
        if let s = word.example, textMatches(s, query: query) { return true }
        if let s = word.quiz, textMatches(s, query: query) { return true }
        if let syn = word.synonyms, !syn.isEmpty {
            let joined = syn.joined(separator: " ")
            if textMatches(joined, query: query) { return true }
            for s in syn where textMatches(s, query: query) {
                return true
            }
        }
        return false
    }

    private static func textMatches(_ text: String, query: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return false }
        return t.range(of: query, options: compareOptions) != nil
    }

    /// Lower rank value = earlier in the list (stronger match).
    private static func rank(word: Word, query: String) -> Int {
        let g = word.german
        if g.range(of: query, options: [.anchored, .caseInsensitive, .diacriticInsensitive]) != nil {
            return 0
        }
        if g.range(of: query, options: compareOptions) != nil {
            return 1
        }
        return 2
    }
}
