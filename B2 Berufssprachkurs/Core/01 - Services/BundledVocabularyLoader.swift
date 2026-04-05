//
//  BundledVocabularyLoader.swift
//  B2 Berufssprachkurs
//
//  Loads `lections.json`, chapter sections, Verben, and Adjektive from the app bundle.
//

import Foundation

enum BundledVocabularyLoader {
    static func load() -> (lections: [Lection], wordsBySection: [String: [Word]]) {
        var lections: [Lection] = []
        var wordsBySection: [String: [Word]] = [:]

        if let url = Bundle.main.url(forResource: "lections", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let lectionsData = try? JSONDecoder().decode(LectionsData.self, from: data) {
            lections = lectionsData.lections
        }

        for chapter in 1...12 {
            for letter in ["A", "B", "C", "D", "E"] {
                loadSectionFile(named: "chapter_\(chapter)_\(letter)", into: &wordsBySection)
            }
        }

        for slug in VocabularyCatalog.verbenPrepositionSlugs {
            loadSectionFile(named: "verben_\(slug)", into: &wordsBySection)
        }
        for slug in VocabularyCatalog.adjektivePrepositionSlugs {
            loadSectionFile(named: "adjektive_\(slug)", into: &wordsBySection)
        }

        return (lections, wordsBySection)
    }

    private static func loadSectionFile(named filename: String, into dict: inout [String: [Word]]) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let sectionFile = try? JSONDecoder().decode(SectionFile.self, from: data) else {
            return
        }
        dict[sectionFile.sectionId] = sectionFile.wordsAsCourseWords()
    }
}

private extension SectionFile {
    func wordsAsCourseWords() -> [Word] {
        words.map { w in
            Word(
                id: w.id,
                german: w.german,
                translation: "",
                synonyms: w.synonyms,
                explanation: w.explanation,
                example: w.example,
                quiz: w.quiz
            )
        }
    }
}
