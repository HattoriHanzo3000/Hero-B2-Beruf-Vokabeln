//
//  VocabularySearchEngine.swift
//  B2 Berufssprachkurs
//
//  Full-text matching across bundled vocabulary and user words (German, translations, hints, synonyms).
//

import Foundation

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

        var pairs: [(sectionId: String, word: Word)] = []
        for (sectionId, words) in dataService.wordsBySection {
            guard dataService.isSectionIncludedInGlobalSearch(sectionId: sectionId, isPremium: isPremium) else { continue }
            for word in words {
                pairs.append((sectionId, word))
            }
        }
        for word in dataService.userCustomWords {
            pairs.append((DataService.userMyWordsSectionId, word))
        }

        let filtered = pairs.filter { pair in
            haystack(for: pair.word, userTranslation: userTranslation(pair.word.id))
                .contains { field in
                    field.range(of: q, options: compareOptions) != nil
                }
        }

        return filtered.sorted { lhs, rhs in
            let o0 = rank(word: lhs.word, query: q)
            let o1 = rank(word: rhs.word, query: q)
            if o0 != o1 { return o0 < o1 }
            if lhs.word.german != rhs.word.german {
                return lhs.word.german.localizedCaseInsensitiveCompare(rhs.word.german) == .orderedAscending
            }
            return lhs.sectionId < rhs.sectionId
        }
    }

    private static func haystack(for word: Word, userTranslation: String) -> [String] {
        var parts: [String] = [
            word.german,
            userTranslation,
            word.translation,
            word.explanation ?? "",
            word.example ?? "",
            word.quiz ?? ""
        ]
        if let syn = word.synonyms {
            parts.append(syn.joined(separator: " "))
        }
        return parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
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
