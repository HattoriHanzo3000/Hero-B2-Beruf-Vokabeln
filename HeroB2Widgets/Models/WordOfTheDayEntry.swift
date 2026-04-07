//
//  WordOfTheDayEntry.swift
//  HeroB2Widgets
//

import WidgetKit

struct WordOfTheDayEntry: TimelineEntry {
    let date: Date
    let word: String
    let translation: String
    let explanation: String?
    let exampleSentence: String?
    let synonyms: String?
    let sectionIcon: String
}
