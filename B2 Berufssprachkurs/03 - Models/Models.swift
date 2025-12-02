//
//  Models.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import Foundation

struct LectionsData: Codable {
    let lections: [Lection]
}

struct Lection: Codable, Identifiable {
    let id: Int
    let title: String
    let sections: [Section]
}

struct Section: Codable, Identifiable {
    let id: String
    let title: String
}

struct WordsData: Codable {
    let words: [SectionWords]
}

struct SectionWords: Codable {
    let sectionId: String
    let words: [Word]
}

struct Word: Codable, Identifiable, Equatable {
    let id: String
    let german: String
    var translation: String
    var synonyms: [String]?
    var explanation: String?
    var example: String?
    var quiz: String?
}

// Model for section files (without translation)
struct SectionFile: Codable {
    let sectionId: String
    let words: [WordWithoutTranslation]
}

struct WordWithoutTranslation: Codable {
    let id: String
    let german: String
    let synonyms: [String]?
    let explanation: String?
    let example: String?
    let quiz: String?
}

// Model for user translations file (flat dictionary: wordId -> { translation: "" })
typealias UserTranslations = [String: TranslationEntry]

struct TranslationEntry: Codable {
    let translation: String
}

