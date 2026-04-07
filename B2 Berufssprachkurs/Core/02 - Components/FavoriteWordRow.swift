//
//  FavoriteWordRow.swift
//  B2 Berufssprachkurs
//
//  Single favorite word row: star toggle, translation editing, optional detail lines.
//

import SwiftData
import SwiftUI

struct FavoriteWordRow: View {
    let word: Word
    let isFavorite: Bool
    @ObservedObject var dataService: DataService
    @Binding var focusedTranslationWordId: String?
    let onFavoriteToggle: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var localTranslation: String = ""

    @Query private var progressMatches: [WordProgress]

    /// Stack / section for tint + badge (matches global search).
    private var favoriteSourceGroup: FavoriteGroupType {
        if let sid = dataService.getSectionId(for: word.id) {
            return dataService.getGroupType(for: sid)
        }
        return .generalWords
    }

    private var sectionAccentColor: Color {
        favoriteSourceGroup.color
    }

    private var contextCaption: String {
        if let sid = dataService.getSectionId(for: word.id) {
            return dataService.searchResultContextLabel(for: sid)
        }
        return Localizable.string(Localizable.generalWords)
    }

    init(
        word: Word,
        isFavorite: Bool,
        dataService: DataService,
        focusedTranslationWordId: Binding<String?>,
        onFavoriteToggle: @escaping () -> Void
    ) {
        self.word = word
        self.isFavorite = isFavorite
        self.dataService = dataService
        self._focusedTranslationWordId = focusedTranslationWordId
        self.onFavoriteToggle = onFavoriteToggle
        let id = word.id
        _progressMatches = Query(filter: #Predicate<WordProgress> { $0.wordId == id })
    }

    private var savedTranslation: String {
        progressMatches.first?.translation ?? ""
    }

    /// Shown text and edit baseline: `WordProgress` when set, otherwise the word’s own translation (e.g. My Words).
    private var trimmedTranslation: String {
        let progress = savedTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !progress.isEmpty { return progress }
        return word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func baselineTranslationForEditing() -> String {
        let progress = savedTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
        if !progress.isEmpty { return savedTranslation }
        return word.translation
    }

    private func beginEditingTranslation() {
        localTranslation = baselineTranslationForEditing()
        focusedTranslationWordId = word.id
    }

    private func syncLocalTranslationWhenNotEditing() {
        guard focusedTranslationWordId != word.id else { return }
        localTranslation = baselineTranslationForEditing()
    }

    private var hasWordDetailLines: Bool {
        let hasErkl = word.explanation?.isEmpty == false
        let hasBeisp = word.example?.isEmpty == false
        let hasSyn = !(word.synonyms?.isEmpty ?? true)
        return hasErkl || hasBeisp || hasSyn
    }

    private static let starColumnWidth: CGFloat = 32

    private var isEditingTranslation: Bool {
        focusedTranslationWordId == word.id
    }

    private var combinedRowAccessibilityLabel: String {
        let summary: String
        if focusedTranslationWordId == word.id {
            summary = String(format: Localizable.string(Localizable.wordRowA11ySummaryEditing), word.german)
        } else if trimmedTranslation.isEmpty {
            summary = String(
                format: Localizable.string(Localizable.wordRowA11ySummaryPromptTranslation),
                word.german,
                Localizable.string(Localizable.addTranslationToWord)
            )
        } else {
            summary = String(
                format: Localizable.string(Localizable.wordRowA11ySummaryWithTranslation),
                word.german,
                Localizable.string(Localizable.translation),
                trimmedTranslation
            )
        }
        return "\(summary). \(contextCaption)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: isEditingTranslation ? .firstTextBaseline : .top, spacing: 10) {
                    Text(word.german)
                        .font(.system(.callout, design: .default, weight: .regular))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isStaticText)

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
                                            .foregroundColor(.primary)
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

            HStack(alignment: .center, spacing: 6) {
                Spacer(minLength: 0)
                SectionContextBadge(caption: contextCaption, accentColor: sectionAccentColor)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
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
            syncLocalTranslationWhenNotEditing()
        }
        .onChange(of: savedTranslation) { _, _ in
            syncLocalTranslationWhenNotEditing()
        }
        .onChange(of: word.translation) { _, _ in
            syncLocalTranslationWhenNotEditing()
        }
        .onChange(of: localTranslation) { _, newValue in
            WordProgress.upsertTranslation(wordId: word.id, text: newValue, in: modelContext)
        }
    }
}
