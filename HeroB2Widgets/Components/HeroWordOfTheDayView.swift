import SwiftUI
import WidgetKit

struct HeroWordOfTheDayView: View {
    var entry: WordOfTheDayEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text("\(Text(Image(systemName: entry.sectionIcon)).font(.system(.body, design: .default, weight: .heavy)))  \(Text(entry.word).font(wordFont))")
                    .foregroundColor(wordOfTheDayAccentColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if family == .systemSmall {
                smallLayout
            } else {
                mediumLayout
            }
        }
        .padding(paddingValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var paddingValue: CGFloat {
        family == .systemSmall ? 10 : 18
    }

    private var wordFont: Font {
        family == .systemSmall
            ? .system(.headline, design: .default, weight: .bold)
            : .system(.title2, design: .default, weight: .bold)
    }

    private var smallLayout: some View {
        ViewThatFits(in: .vertical) {
            detailsContent(showExample: true, showTranslation: true, showExplanation: true, showSynonyms: false)
            detailsContent(showExample: true, showTranslation: true, showExplanation: false, showSynonyms: false)
            detailsContent(showExample: true, showTranslation: false, showExplanation: false, showSynonyms: false)
        }
    }

    private var mediumLayout: some View {
        ViewThatFits(in: .vertical) {
            detailsContent(showExample: true, showTranslation: true, showExplanation: true, showSynonyms: true)
            detailsContent(showExample: true, showTranslation: true, showExplanation: true, showSynonyms: false)
            detailsContent(showExample: true, showTranslation: true, showExplanation: false, showSynonyms: false)
        }
    }

    @ViewBuilder
    private func detailsContent(
        showExample: Bool,
        showTranslation: Bool,
        showExplanation: Bool,
        showSynonyms: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if showExample, let example = normalized(entry.exampleSentence) {
                detailText(labelKey: "word_row_detail_label_example", value: example, lineLimit: 2)
            }

            if showTranslation, let translation = normalized(entry.translation) {
                detailText(labelKey: "word_row_detail_label_translation", value: translation, lineLimit: 1)
            }

            if showExplanation, let explanation = normalized(entry.explanation) {
                detailText(labelKey: "word_row_detail_label_explanation", value: explanation, lineLimit: 2)
            }

            if showSynonyms, let synonyms = normalized(entry.synonyms) {
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

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var wordOfTheDayAccentColor: Color {
        // Exact colors from HeaderView+Chrome.swift
        if colorScheme == .dark {
            return Color(red: 0.42, green: 0.82, blue: 0.58)
        } else {
            return Color(red: 0.06, green: 0.38, blue: 0.26)
        }
    }

    private func localizedString(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", comment: "")
    }
}
