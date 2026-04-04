//
//  MyWordRow.swift
//  B2 Berufssprachkurs
//
//  Row for a custom word (same structure & typography as `WordRow` in `WordsListView`).
//

import SwiftUI

extension View {
    /// Wraps content in a plain `Button` only when `action` is non-nil (edit mode: tap opens word sheet without nesting a button around delete).
    @ViewBuilder
    func myWordEditSheetTap(_ action: (() -> Void)?) -> some View {
        if let action {
            Button(action: action) {
                self
            }
            .buttonStyle(.plain)
        } else {
            self
        }
    }
}

struct MyWordRow: View {
    let word: Word
    let isFavorite: Bool
    let onEditTranslation: () -> Void
    let onFavoriteToggle: () -> Void
    /// When `false`, the favorite star column is an empty spacer (same width preserved).
    var showsFavoriteControl: Bool = true
    /// When set, the star is replaced by this delete control in the same leading column (list edit mode).
    var onDelete: (() -> Void)? = nil
    /// When set, tapping the word block (not delete) runs this — avoids wrapping the whole row in an outer `Button`.
    var openEditSheet: (() -> Void)? = nil
    /// When `false`, translation/pencil are not `Button`s (e.g. wrapped by `openEditSheet`).
    var translationButtonsEnabled: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    private static let starColumnWidth: CGFloat = 32

    private var trimmedTranslation: String {
        word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var translationTextColor: Color {
        WordListTranslationTextStyle.color(for: .myWords, colorScheme: colorScheme)
    }

    private func attributedText(
        label: String,
        value: String,
        labelFont: Font = .system(.caption, design: .rounded).weight(.semibold),
        valueFont: Font = .system(.caption, design: .rounded),
        labelColor: Color = .secondary,
        valueColor: Color = .primary
    ) -> AttributedString {
        var fullText = AttributedString("\(label)\(value)")
        if let labelRange = fullText.range(of: label) {
            fullText[labelRange].font = labelFont
            fullText[labelRange].foregroundColor = labelColor
        }
        if let valueRange = fullText.range(of: value) {
            fullText[valueRange].font = valueFont
            fullText[valueRange].foregroundColor = valueColor
        }
        return fullText
    }

    private var hasWordDetailLines: Bool {
        let hasErkl = word.explanation?.isEmpty == false
        let hasBeisp = word.example?.isEmpty == false
        let hasSyn = !(word.synonyms?.isEmpty ?? true)
        return hasErkl || hasBeisp || hasSyn
    }

    /// Edit mode: match system reorder control (``line.3.horizontal``) vertical centering.
    private var rowStackAlignment: VerticalAlignment {
        onDelete != nil ? .center : .top
    }

    @ViewBuilder
    private var translationColumn: some View {
        if trimmedTranslation.isEmpty {
            Color.clear
                .frame(minWidth: 96, maxWidth: .infinity)
                .accessibilityHidden(true)
        } else if translationButtonsEnabled {
            Button(action: onEditTranslation) {
                Text(trimmedTranslation)
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .foregroundColor(translationTextColor)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 96, maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                String(format: Localizable.string(Localizable.myWordsRowTranslationA11yLabel), trimmedTranslation)
            )
            .accessibilityHint(Localizable.string(Localizable.myWordsRowTranslationEditA11yHint))
        } else {
            Text(trimmedTranslation)
                .font(.system(.subheadline, design: .default, weight: .medium))
                .foregroundColor(translationTextColor)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 96, maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(
                    String(format: Localizable.string(Localizable.myWordsRowTranslationA11yLabel), trimmedTranslation)
                )
        }
    }

    @ViewBuilder
    private var leadingAccessory: some View {
        if let delete = onDelete {
            Button(role: .destructive, action: delete) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundStyle(.red)
                    .frame(width: Self.starColumnWidth, alignment: .center)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Localizable.string(Localizable.myWordsDeleteWord))
            .accessibilityHint(Localizable.string(Localizable.myWordsDeleteWordHint))
        } else if showsFavoriteControl {
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isFavorite ? Color("AppYellow") : .secondary)
                    .symbolEffect(.bounce, value: isFavorite)
                    .frame(width: Self.starColumnWidth)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Localizable.string(isFavorite ? Localizable.myWordsRowFavoriteRemoveA11y : Localizable.myWordsRowFavoriteAddA11y)
            )
            .accessibilityValue(
                Localizable.string(isFavorite ? Localizable.myWordsRowFavoriteValueYesA11y : Localizable.myWordsRowFavoriteValueNoA11y)
            )
            .accessibilityHint(
                String(format: Localizable.string(Localizable.myWordsRowFavoriteHintA11y), word.german)
            )
            .accessibilityAddTraits(isFavorite ? .isSelected : [])
        } else {
            Color.clear.frame(width: Self.starColumnWidth, height: 0)
        }
    }

    var body: some View {
        HStack(alignment: rowStackAlignment, spacing: 12) {
            leadingAccessory

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    Text(word.german)
                        .font(.system(.body, design: .default, weight: .regular))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(minWidth: 72, maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    translationColumn
                }

                if hasWordDetailLines {
                    VStack(alignment: .leading, spacing: 6) {
                        if let explanation = word.explanation, !explanation.isEmpty {
                            Text(
                                attributedText(
                                    label: "erkl: ",
                                    value: explanation,
                                    labelFont: WordListRowDetailTextStyle.explanationLabelFont,
                                    valueFont: WordListRowDetailTextStyle.explanationValueFont,
                                    labelColor: .secondary,
                                    valueColor: .primary
                                )
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel(
                                String(format: Localizable.string(Localizable.myWordsRowExplanationA11y), explanation)
                            )
                        }

                        if let example = word.example, !example.isEmpty {
                            Text(
                                attributedText(
                                    label: "beisp: ",
                                    value: example,
                                    labelFont: WordListRowDetailTextStyle.explanationLabelFont,
                                    valueFont: WordListRowDetailTextStyle.explanationValueFont,
                                    labelColor: .secondary,
                                    valueColor: .primary
                                )
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel(
                                String(format: Localizable.string(Localizable.myWordsRowExampleA11y), example)
                            )
                        }

                        if let synonyms = word.synonyms, !synonyms.isEmpty {
                            let synonymsText = synonyms.joined(separator: ", ")
                            Text(
                                attributedText(
                                    label: "syn: ",
                                    value: synonymsText,
                                    labelFont: WordListRowDetailTextStyle.explanationLabelFont,
                                    valueFont: WordListRowDetailTextStyle.explanationValueFont,
                                    labelColor: .secondary,
                                    valueColor: .primary
                                )
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel(
                                String(format: Localizable.string(Localizable.myWordsRowSynonymsA11y), synonymsText)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .myWordEditSheetTap(openEditSheet)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(format: Localizable.string(Localizable.myWordsRowContainerA11y), word.german))
    }
}
