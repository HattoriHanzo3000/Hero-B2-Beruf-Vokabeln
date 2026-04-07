//
//  HeroWordOfTheDayView.swift
//  HeroB2Widgets
//

import SwiftUI

struct HeroWordOfTheDayView: View {
    var entry: WordOfTheDayEntry
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Main Word Section (matching HeaderView+HeroContent.swift)
            HStack(alignment: .top) {
                Text("\(Text(Image(systemName: entry.sectionIcon)).fontWeight(.bold))  \(Text(entry.word).font(.title2).fontWeight(.bold))")
                    .foregroundColor(wordOfTheDayAccentColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Detail Rows with Graceful Degradation
            ViewThatFits(in: .vertical) {
                // Option 1: Full View (Example, Translation, Explanation, Synonyms)
                detailsContent(showExplanation: true, showSynonyms: true)
                
                // Option 2: Compact View (Example, Translation, Explanation)
                detailsContent(showExplanation: true, showSynonyms: false)
                
                // Option 3: Minimal View (Example, Translation)
                detailsContent(showExplanation: false, showSynonyms: false)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func detailsContent(showExplanation: Bool, showSynonyms: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let example = entry.exampleSentence, !example.isEmpty {
                detailText(labelKey: "word_row_detail_label_example", value: example, lineLimit: 2)
            }

            if !entry.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                detailText(labelKey: "word_row_detail_label_translation", value: entry.translation, lineLimit: 1)
            }

            if showExplanation, let explanation = entry.explanation, !explanation.isEmpty {
                detailText(labelKey: "word_row_detail_label_explanation", value: explanation, lineLimit: 2)
            }

            if showSynonyms, let synonyms = entry.synonyms, !synonyms.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                detailText(labelKey: "word_row_detail_label_synonyms", value: synonyms, lineLimit: 1)
            }
        }
    }

    private func detailText(labelKey: String, value: String, lineLimit: Int) -> some View {
        Text(attributedText(label: localizedString(labelKey), value: value))
            .lineLimit(lineLimit)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func attributedText(label: String, value: String) -> AttributedString {
        var fullText = AttributedString("\(label)\(value)")
        
        // Exact fonts from HeaderView+Chrome.swift
        let labelFont = Font.system(.subheadline, design: .default, weight: .bold).width(.condensed)
        let valueFont = Font.system(.subheadline, design: .default, weight: .medium).width(.condensed)
        
        if let labelRange = fullText.range(of: label) {
            fullText[labelRange].font = labelFont
            fullText[labelRange].foregroundColor = .white.opacity(0.7)
        }
        
        if let valueRange = fullText.range(of: value) {
            fullText[valueRange].font = valueFont
            fullText[valueRange].foregroundColor = .white
        }
        
        return fullText
    }

    private var wordOfTheDayAccentColor: Color {
        // Exact colors from HeaderView+Chrome.swift
        if colorScheme == .dark {
            return Color(red: 0.42, green: 0.82, blue: 0.58)
        } else {
            return Color(red: 0.06, green: 0.38, blue: 0.26)
        }
    }

    // Helper to simulate NSLocalizedString for the specific keys we need
    private func localizedString(_ key: String) -> String {
        switch key {
        case "word_row_detail_label_explanation": return "expl.: "
        case "word_row_detail_label_example": return "ex.: "
        case "word_row_detail_label_synonyms": return "syn.: "
        case "word_row_detail_label_translation": return "trans.: "
        default: return key
        }
    }
}
