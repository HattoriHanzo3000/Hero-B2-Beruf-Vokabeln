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

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var localTranslation: String = ""

    @Query private var progressMatches: [WordProgress]

    private var translationGroup: FavoriteGroupType {
        if let sid = dataService.getSectionId(for: word.id) {
            return dataService.getGroupType(for: sid)
        }
        return .generalWords
    }

    private var translationTextColor: Color {
        WordListTranslationTextStyle.color(for: translationGroup, colorScheme: colorScheme)
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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isFavorite ? Color("AppYellow") : .secondary)
                    .symbolEffect(.bounce, value: isFavorite)
                    .frame(width: Self.starColumnWidth)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            .accessibilityValue(isFavorite ? "Favorited" : "Not favorited")
            .accessibilityHint("Toggle favorite for \(word.german)")
            .accessibilityAddTraits(isFavorite ? .isSelected : [])

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: isEditingTranslation ? .firstTextBaseline : .top, spacing: 12) {
                    Text(word.german)
                        .font(.system(.body, design: .default, weight: .regular))
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
                                            .frame(minWidth: 44, alignment: .trailing)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .accessibilityLabel(Localizable.string(Localizable.addTranslationToWord))
                                    .accessibilityHint("Opens the keyboard to type your translation")
                                } else {
                                    Button(action: beginEditingTranslation) {
                                        Text(trimmedTranslation)
                                            .font(.system(.subheadline, design: .default, weight: .medium))
                                            .foregroundColor(translationTextColor)
                                            .multilineTextAlignment(.trailing)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .buttonStyle(.plain)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .accessibilityLabel("Translation: \(trimmedTranslation)")
                                    .accessibilityHint("Double tap to edit translation")
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
                            .accessibilityLabel("Explanation: \(explanation)")
                        }

                        if let example = word.example, !example.isEmpty {
                            Text(
                                AttributedString.b2_wordListDetailLine(
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
                            .accessibilityLabel("Example: \(example)")
                        }

                        if let synonyms = word.synonyms, !synonyms.isEmpty {
                            let synonymsText = synonyms.joined(separator: ", ")
                            Text(
                                AttributedString.b2_wordListDetailLine(
                                    label: "syn: ",
                                    value: synonymsText,
                                    labelFont: WordListRowDetailTextStyle.labelFont,
                                    valueFont: WordListRowDetailTextStyle.valueFont,
                                    labelColor: .secondary,
                                    valueColor: .primary
                                )
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel("Synonyms: \(synonymsText)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                focusedTranslationWordId == word.id
                    ? "\(word.german). Editing translation"
                    : (trimmedTranslation.isEmpty
                        ? "\(word.german). \(Localizable.string(Localizable.addTranslationToWord))"
                        : "\(word.german). Translation: \(trimmedTranslation)")
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Word row for \(word.german)")
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
