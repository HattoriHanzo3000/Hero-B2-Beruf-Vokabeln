import SwiftUI
import WidgetKit

struct HeroWordOfTheDayView: View {
    var entry: WordOfTheDayEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Group {
            if family == .systemSmall { smallLayout } else { mediumLayout }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var wordFont: Font {
        .system(.headline, design: .default, weight: .bold)
    }

    private var wordLineLimit: Int {
        2
    }

    private var smallLayout: some View {
        detailsContent(
            showExample: true,
            showTranslation: true,
            showExplanation: true,
            showSynonyms: true,
            exampleLineLimit: 1,
            translationLineLimit: 1,
            explanationLineLimit: 1,
            synonymsLineLimit: 1
        )
    }

    private var mediumLayout: some View {
        detailsContent(
            showExample: true,
            showTranslation: true,
            showExplanation: true,
            showSynonyms: true,
            exampleLineLimit: 1,
            translationLineLimit: 1,
            explanationLineLimit: 1,
            synonymsLineLimit: 1
        )
    }

    @ViewBuilder
    private func detailsContent(
        showExample: Bool,
        showTranslation: Bool,
        showExplanation: Bool,
        showSynonyms: Bool,
        exampleLineLimit: Int,
        translationLineLimit: Int,
        explanationLineLimit: Int,
        synonymsLineLimit: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                Text(entry.word)
                    .font(wordFont)
                    .foregroundColor(wordOfTheDayAccentColor)
                    .lineLimit(wordLineLimit)
                    .minimumScaleFactor(0.85)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showExample, let example = normalized(entry.exampleSentence) {
                detailText(
                    labelKey: "word_row_detail_label_example",
                    value: example,
                    lineLimit: exampleLineLimit
                )
            }

            if showTranslation, let translation = normalized(entry.translation) {
                detailText(
                    labelKey: "word_row_detail_label_translation",
                    value: translation,
                    lineLimit: translationLineLimit
                )
            }

            if showExplanation, let explanation = normalized(entry.explanation) {
                detailText(
                    labelKey: "word_row_detail_label_explanation",
                    value: explanation,
                    lineLimit: explanationLineLimit
                )
            }

            if showSynonyms, let synonyms = normalized(entry.synonyms) {
                detailText(
                    labelKey: "word_row_detail_label_synonyms",
                    value: synonyms,
                    lineLimit: synonymsLineLimit
                )
            }
        }
    }

    private func detailText(labelKey: String, value: String, lineLimit: Int) -> some View {
        Text(attributedText(label: localizedString(labelKey), value: value))
            .truncationMode(.tail)
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

    private var wordOfTheDayAccentColor: Color {
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
