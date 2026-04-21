//
//  WordRow.swift
//  B2 Berufssprachkurs
//
//  Interactive word row with translation editing, details, and favorite toggle.
//  Created: 21.04.26.
//

import SwiftData
import SwiftUI

struct WordRow: View {
    // MARK: - State

    let word: Word
    let isFavorite: Bool
    @ObservedObject var dataService: DataService
    let translationTextColor: Color
    @Binding var focusedTranslationWordId: String?
    let onFavoriteToggle: () -> Void
    var usesFloatingKeyboardAccessory: Bool = false

    @Environment(\.modelContext) private var modelContext
    @State private var localTranslation: String = ""
    @Query private var progressMatches: [WordProgress]

    init(
        word: Word,
        isFavorite: Bool,
        dataService: DataService,
        translationTextColor: Color,
        focusedTranslationWordId: Binding<String?>,
        onFavoriteToggle: @escaping () -> Void,
        usesFloatingKeyboardAccessory: Bool = false
    ) {
        self.word = word
        self.isFavorite = isFavorite
        self.dataService = dataService
        self.translationTextColor = translationTextColor
        self._focusedTranslationWordId = focusedTranslationWordId
        self.onFavoriteToggle = onFavoriteToggle
        self.usesFloatingKeyboardAccessory = usesFloatingKeyboardAccessory
        let id = word.id
        _progressMatches = Query(filter: #Predicate<WordProgress> { $0.wordId == id })
    }

    // MARK: - View Layout

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            contentStack
            favoriteButtonRow
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .onAppear {
            localTranslation = savedTranslation
        }
        .onChange(of: savedTranslation) { _, newValue in
            guard !isEditingTranslation else { return }
            localTranslation = newValue
        }
        .onChange(of: localTranslation) { _, newValue in
            WordProgress.upsertTranslation(wordId: word.id, text: newValue, in: modelContext)
        }
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: isEditingTranslation ? .firstTextBaseline : .top, spacing: 10) {
                germanLemma
                translationArea
            }

            if hasWordDetailLines {
                detailLines
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(combinedRowAccessibilityLabel)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var translationArea: some View {
        ZStack(alignment: .topTrailing) {
            translationTextField
            if !isEditingTranslation {
                translationDisplay
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var translationTextField: some View {
        TranslationTextField(
            text: $localTranslation,
            wordId: word.id,
            focusedWordId: $focusedTranslationWordId,
            placeholder: Localizable.string(Localizable.translation),
            showsKeyboardAccessory: !usesFloatingKeyboardAccessory
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
    }

    @ViewBuilder
    private var translationDisplay: some View {
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

    private var detailLines: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let explanation = nonEmpty(word.explanation) {
                wordDetailLine(
                    label: Localizable.string(Localizable.wordRowDetailLabelExplanation),
                    value: explanation,
                    accessibilityFormat: Localizable.string(Localizable.wordRowDetailExplanationA11y)
                )
            }

            if let example = nonEmpty(word.example) {
                wordDetailLine(
                    label: Localizable.string(Localizable.wordRowDetailLabelExample),
                    value: example,
                    accessibilityFormat: Localizable.string(Localizable.wordRowDetailExampleA11y)
                )
            }

            if let synonymsText = nonEmpty(word.synonyms?.joined(separator: ", ")) {
                wordDetailLine(
                    label: Localizable.string(Localizable.wordRowDetailLabelSynonyms),
                    value: synonymsText,
                    accessibilityFormat: Localizable.string(Localizable.wordRowDetailSynonymsA11y)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var favoriteButtonRow: some View {
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

    private var germanLemma: some View {
        Text(word.german)
            .font(.system(.callout, design: .default, weight: .regular))
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Helpers

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

    private var isEditingTranslation: Bool {
        focusedTranslationWordId == word.id
    }

    private var combinedRowAccessibilityLabel: String {
        if isEditingTranslation {
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

    @ViewBuilder
    private func wordDetailLine(
        label: String,
        value: String,
        accessibilityFormat: String
    ) -> some View {
        Text(
            AttributedString.b2_wordListDetailLine(
                label: label,
                value: value,
                labelFont: WordListRowDetailTextStyle.explanationLabelFont,
                valueFont: WordListRowDetailTextStyle.explanationValueFont,
                labelColor: .secondary,
                valueColor: .primary
            )
        )
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(String(format: accessibilityFormat, value))
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}

// MARK: - Preview

#Preview {
    WordRowPreview()
        .padding()
        .background(LearningSurfaceColors.generalWords)
        .modelContainer(for: [WordProgress.self], inMemory: true)
}

private struct WordRowPreview: View {
    @State private var focusedWordId: String?

    private let previewWord = Word(
        id: "preview-word-1",
        german: "die Verantwortung",
        translation: "",
        synonyms: ["die Pflicht", "die Zustaendigkeit"],
        explanation: "Die Aufgabe, fuer etwas einzustehen und Entscheidungen bewusst zu treffen.",
        example: "Im Team trage ich Verantwortung fuer die Projektplanung.",
        quiz: nil
    )

    var body: some View {
        WordRow(
            word: previewWord,
            isFavorite: false,
            dataService: DataService(),
            translationTextColor: .secondary,
            focusedTranslationWordId: $focusedWordId,
            onFavoriteToggle: {}
        )
    }
}
