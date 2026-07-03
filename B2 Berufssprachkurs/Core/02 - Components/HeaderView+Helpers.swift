//
//  HeaderView+Helpers.swift
//  B2 Berufssprachkurs
//

import SwiftUI

extension HeaderView {
    func updateWordOfTheDay() {
        wordOfTheDay = dataService.getWordOfTheDay()
    }

    func displayedTranslation(for word: Word) -> String {
        if let stored = wordProgressRecords.first(where: { $0.wordId == word.id })?.translation,
           !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return stored
        }
        return word.translation
    }

    func attributedText(
        label: String,
        value: String,
        labelFont: Font = .system(.subheadline, design: .default, weight: .bold).width(.condensed),
        valueFont: Font = .system(.subheadline, design: .default, weight: .bold).width(.condensed),
        labelColor: Color? = nil,
        valueColor: Color? = nil
    ) -> AttributedString {
        var fullText = AttributedString("\(label)\(value)")
        if let labelRange = fullText.range(of: label) {
            fullText[labelRange].font = labelFont
            if let labelColor {
                fullText[labelRange].foregroundColor = labelColor
            }
        }
        if let valueRange = fullText.range(of: value) {
            fullText[valueRange].font = valueFont
            if let valueColor {
                fullText[valueRange].foregroundColor = valueColor
            }
        }
        return fullText
    }

    func findSectionId(for word: Word) -> String? {
        for (sectionId, words) in dataService.wordsBySection {
            if words.contains(where: { $0.id == word.id }) {
                return sectionId
            }
        }
        return nil
    }

    func wordStackIcon(for word: Word) -> String {
        guard let sectionId = findSectionId(for: word) else {
            return "book.fill"
        }

        if sectionId == DataService.userMyWordsSectionId {
            return "person.fill"
        }
        if sectionId.hasPrefix("VERBEN_") {
            return "figure.run"
        } else if sectionId.hasPrefix("ADJEKTIVE_") {
            return "paintpalette.fill"
        } else {
            return "book.fill"
        }
    }

    func wordOfTheDayGeneralSectionBadgeCaption(for word: Word) -> String? {
        guard let sectionId = dataService.getSectionId(for: word.id),
              dataService.getGroupType(for: sectionId) == .generalWords else {
            return nil
        }
        return sectionId
    }

    func wordOfTheDayHeadlineAccessibilityLabel(for word: Word) -> String {
        if let sectionLabel = wordOfTheDayGeneralSectionBadgeCaption(for: word) {
            return "\(word.german). \(sectionLabel)"
        }
        return word.german
    }
}
