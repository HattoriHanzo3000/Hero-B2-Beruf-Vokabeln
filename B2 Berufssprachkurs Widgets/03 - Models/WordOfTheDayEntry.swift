//
//  WordOfTheDayEntry.swift
//  B2 Berufssprachkurs
//
//  Timeline entry model for the Word of the Day widget.
//  Created: 07.04.26.
//

import WidgetKit

struct WordOfTheDayEntry: TimelineEntry {
    let date: Date
    let word: String
    let translation: String
    let exampleSentence: String?
}
