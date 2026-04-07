//
//  WordRow.swift
//  B2 Berufssprachkurs
//

import SwiftData
import SwiftUI

struct WordRow: View {
    let word: Word
    let isFavorite: Bool
    @ObservedObject var dataService: DataService
    let translationTextColor: Color
    @Binding var focusedTranslationWordId: String?
    let onFavoriteToggle: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var localTranslation: String = ""

    @Query private var progressMatches: [WordProgress]

    init(
        word: Word,
        isFavorite: Bool,
        dataService: DataService,
        translationTextColor: Color,
        focusedTranslationWordId: Binding<String?>,
        onFavoriteToggle: @escaping () -> Void
    ) {
        self.word = word
        self.isFavorite = isFavorite
        self.dataService = dataService
        self.translationTextColor = translationTextColor
        self._focusedTranslationWordId = focusedTranslationWordId
        self.onFavoriteToggle = onFavoriteToggle
        let id = word.id
        _progressMatches = Query(filter: #Predicate<WordProgress> { $0.wordId == id })
    }

    private var savedTranslation: String {
        progressMatches.first?.translation ?? ""
    }

    private var trimmedTranslation: String {
        savedTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func beginEditingTranslation() {
        localTranslation = savedTranslation
        focusedTranslationWordId = word.id
    }

    private var hasWordDetailLines: Bool {
        let hasErkl = word.explanation?.isEmpty == false
        let hasBeisp = word.example?.isEmpty == false
        let hasSyn = !(word.synonyms?.isEmpty ?? true)
        return hasErkl || hasBeisp || hasSyn
    }

    private static let starColumnWidth: CGFloat = 32

    private var germanLemma: some View {
        Text(word.german)
            .font(.system(.callout, design: .default, weight: .regular))
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isStaticText)
    }

    private var isEditingTranslation: Bool {
        focusedTranslationWordId == word.id
    }

    var body: some View {
        /// Trailing star sits in its own row (like `SectionContextBadge` in `FavoriteWordRow`) so it does not crowd the lemma / translation line.
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: isEditingTranslation ? .firstTextBaseline : .top, spacing: 10) {
                    germanLemma
                    ZStack(alignment: .topTrailing) {
                        TranslationTextField(
                            text: $localTranslation,
                            wordId: word.id,
                            focusedWordId: $focusedTranslationWordId,
                            placeholder: Localizable.string(Localizable.translation)
                        )
                        .opacity(isEditingTranslation ? 1 : 0)
                        .allowsHitTesting(isEditingTranslation)
                        .accessibilityHidden(!isEditingTranslation)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .alignmentGuide(.firstTextBaseline) { _ in
                            isEditingTranslation
                                ? TranslationTextField.rowFirstBaselineFromTopForBodyStyle()
                                : 0
                        }

                        if !isEditingTranslation {
                            Group {
                                if trimmedTranslation.isEmpty {
                                    Button(action: beginEditingTranslation) {
                                        Image(systemName: "pencil.line")
                                            .font(.system(size: 20, weight: .regular))
                                            .foregroundStyle(.secondary)
                                            .frame(width: Self.starColumnWidth, alignment: .center)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .accessibilityLabel(Localizable.string(Localizable.addTranslationToWord))
                                    .accessibilityHint(Localizable.string(Localizable.wordRowTranslationOpenKeyboardHintA11y))
                                } else {
                                    Button(action: beginEditingTranslation) {
                                        Text(trimmedTranslation)
                                            .font(.system(.callout, design: .default, weight: .regular))
                                            .foregroundColor(translationTextColor)
                                            .multilineTextAlignment(.trailing)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .accessibilityLabel(
                                        String(format: Localizable.string(Localizable.wordRowTranslationDisplayA11y), trimmedTranslation)
                                    )
                                    .accessibilityHint(Localizable.string(Localizable.wordRowTranslationEditHintA11y))
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                if hasWordDetailLines {
                    VStack(alignment: .leading, spacing: 6) {
                        if let explanation = word.explanation, !explanation.isEmpty {
                            Text(
                                AttributedString.b2_wordListDetailLine(
                                    label: Localizable.string(Localizable.wordRowDetailLabelExplanation),
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
                                String(format: Localizable.string(Localizable.wordRowDetailExplanationA11y), explanation)
                            )
                        }

                        if let example = word.example, !example.isEmpty {
                            Text(
                                AttributedString.b2_wordListDetailLine(
                                    label: Localizable.string(Localizable.wordRowDetailLabelExample),
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
                                String(format: Localizable.string(Localizable.wordRowDetailExampleA11y), example)
                            )
                        }

                        if let synonyms = word.synonyms, !synonyms.isEmpty {
                            let synonymsText = synonyms.joined(separator: ", ")
                            Text(
                                AttributedString.b2_wordListDetailLine(
                                    label: Localizable.string(Localizable.wordRowDetailLabelSynonyms),
                                    value: synonymsText,
                                    labelFont: WordListRowDetailTextStyle.labelFont,
                                    valueFont: WordListRowDetailTextStyle.valueFont,
                                    labelColor: .secondary,
                                    valueColor: .primary
                                )
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel(
                                String(format: Localizable.string(Localizable.wordRowDetailSynonymsA11y), synonymsText)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(combinedRowAccessibilityLabel)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Spacer(minLength: 0)
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(isFavorite ? Color("AppYellow") : .secondary)
                        .symbolEffect(.bounce, value: isFavorite)
                        .frame(width: Self.starColumnWidth, alignment: .center)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isFavorite
                        ? Localizable.string(Localizable.wordRowFavoriteRemoveA11y)
                        : Localizable.string(Localizable.wordRowFavoriteAddA11y)
                )
                .accessibilityValue(
                    isFavorite
                        ? Localizable.string(Localizable.wordRowFavoriteValueFavoritedA11y)
                        : Localizable.string(Localizable.wordRowFavoriteValueNotFavoritedA11y)
                )
                .accessibilityHint(String(format: Localizable.string(Localizable.wordRowFavoriteHintFormat), word.german))
                .accessibilityAddTraits(isFavorite ? .isSelected : [])
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .onAppear {
            localTranslation = savedTranslation
        }
        .onChange(of: savedTranslation) { _, newValue in
            guard focusedTranslationWordId != word.id else { return }
            localTranslation = newValue
        }
        .onChange(of: localTranslation) { _, newValue in
            WordProgress.upsertTranslation(wordId: word.id, text: newValue, in: modelContext)
        }
    }

    private var combinedRowAccessibilityLabel: String {
        if focusedTranslationWordId == word.id {
            return String(format: Localizable.string(Localizable.wordRowA11ySummaryEditing), word.german)
        }
        if trimmedTranslation.isEmpty {
            return String(
                format: Localizable.string(Localizable.wordRowA11ySummaryPromptTranslation),
                word.german,
                Localizable.string(Localizable.addTranslationToWord)
            )
        }
        return String(
            format: Localizable.string(Localizable.wordRowA11ySummaryWithTranslation),
            word.german,
            Localizable.string(Localizable.translation),
            trimmedTranslation
        )
    }
}
