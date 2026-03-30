//
//  FavoritesView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @EnvironmentObject private var dataService: DataService
    @Query(sort: \WordProgress.wordId) private var wordProgressList: [WordProgress]

    @State private var navigateToStudy = false
    @State private var focusedTranslationWordId: String?
    @StateObject private var keyboardNavBridge = WordListKeyboardNavBridge()

    private var progressByWordId: [String: WordProgress] {
        Dictionary(uniqueKeysWithValues: wordProgressList.map { ($0.wordId, $0) })
    }

    private func userTranslation(for wordId: String) -> String {
        let progressText = progressByWordId[wordId]?.translation ?? ""
        if !progressText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return progressText
        }
        return favoriteWords.first(where: { $0.id == wordId })?.translation ?? ""
    }

    var favoriteWords: [Word] {
        dataService.getFavoriteWords()
    }
    
    private func attributedText(label: String, value: String, labelFont: Font = .caption.weight(.semibold), valueFont: Font = .caption, labelColor: Color = .secondary, valueColor: Color = .primary) -> AttributedString {
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
    
    var body: some View {
        ZStack {
            Color("AppYellow").opacity(0.08)
                .ignoresSafeArea()

            if favoriteWords.isEmpty {
                favoritesEmptyCenteredView
            } else {
                favoritesListView
            }
        }
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                dataService: dataService,
                filterBySectionId: nil, // Favorites: process all sections
                studyAllMode: false, // Study only favorites
                favoritesOnly: true // Only show favorite words
            )
            .environmentObject(dataService)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !favoriteWords.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    WordListPrintButton(
                        pdfURL: { generateFavoritesPDF() },
                        jobName: Localizable.string(Localizable.favorites)
                    )
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !favoriteWords.isEmpty {
                FlashcardsButton.bottomTrailingInset(
                    isEnabled: true,
                    accent: Color("AppYellow"),
                    inactiveTapBehavior: .silent
                ) {
                    navigateToStudy = true
                }
            }
        }
        .hidesBottomBarWhenPushed(true)
        .environmentObject(keyboardNavBridge)
        .onAppear {
            keyboardNavBridge.attachHandlers(
                onPrevious: navigateToPreviousTranslationField,
                onNext: navigateToNextTranslationField,
                onDismiss: { focusedTranslationWordId = nil }
            )
            syncTranslationKeyboardNavBridge()
        }
    }

    private func syncTranslationKeyboardNavBridge() {
        guard let fid = focusedTranslationWordId,
              let idx = favoriteWords.firstIndex(where: { $0.id == fid }) else {
            keyboardNavBridge.syncCanNavigate(canPrevious: false, canNext: false)
            return
        }
        keyboardNavBridge.syncCanNavigate(
            canPrevious: idx > 0,
            canNext: idx < favoriteWords.count - 1
        )
    }

    private func navigateToPreviousTranslationField() {
        guard let fid = focusedTranslationWordId,
              let idx = favoriteWords.firstIndex(where: { $0.id == fid }),
              idx > 0 else { return }
        focusedTranslationWordId = favoriteWords[idx - 1].id
    }

    private func navigateToNextTranslationField() {
        guard let fid = focusedTranslationWordId,
              let idx = favoriteWords.firstIndex(where: { $0.id == fid }),
              idx < favoriteWords.count - 1 else { return }
        focusedTranslationWordId = favoriteWords[idx + 1].id
    }

    private func generateFavoritesPDF() -> URL {
        let wordData = WordListShareManager.wordDataForPDF(
            words: favoriteWords,
            translationProvider: { userTranslation(for: $0.id) }
        )
        let pdfInfo = PDFGenerationService.PDFInfo(
            lectionTitle: Localizable.string(Localizable.favorites),
            lectionNumber: nil,
            sectionTitle: "",
            sectionLetter: nil,
            headerColor: Color("AppYellow"),
            words: wordData,
            fileName: "Favorites",
            showsLectionSectionIndexing: false
        )
        return PDFGenerationService.generateWordsListPDF(info: pdfInfo)
    }

    /// No scroll header — only the soft star, title, and hint, centered between safe areas (back stays in the nav bar).
    private var favoritesEmptyCenteredView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 14) {
                Image(systemName: "star")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                Text(Localizable.string(Localizable.noFavoritesFound))
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(Localizable.string(Localizable.noFavoritesFoundMessage))
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 36)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var favoritesListView: some View {
        ScrollViewReader { proxy in
                List {
                    // Header + word rows — same list style as WordsListView for spacing under the header divider
                    SwiftUI.Section {
                        EmptyView()
                    } header: {
                        ScrollableStackRootHeader(
                            accent: Color("AppYellow"),
                            icon: "star.fill",
                            title: Localizable.string(Localizable.favorites),
                            showsDivider: false
                        )
                    }

                    SwiftUI.Section {
                        ForEach(favoriteWords) { word in
                            FavoriteWordRow(
                                word: word,
                                isFavorite: dataService.isFavorite(wordId: word.id),
                                dataService: dataService,
                                focusedTranslationWordId: $focusedTranslationWordId,
                                onFavoriteToggle: {
                                    _ = dataService.toggleFavorite(wordId: word.id)
                                    HapticManager.shared.lightImpact()
                                }
                            )
                            .id(word.id)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.never)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, 8, for: .scrollContent)
                .contentMargins(.bottom, FlashcardsButton.fabSize + 24, for: .scrollContent)
                .accessibilityLabel("Favorites list")
                .accessibilityHint("List of favorite German words with translations, explanations, and synonyms")
                .onChange(of: focusedTranslationWordId) { _, newValue in
                    syncTranslationKeyboardNavBridge()
                    guard let id = newValue else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
                .onChange(of: favoriteWords.count) { _, _ in
                    syncTranslationKeyboardNavBridge()
                }
        }
    }
}

// MARK: - Favorite Word Row
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

    private var translationGroup: DataService.FavoriteGroupType {
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

    private func attributedText(label: String, value: String, labelFont: Font = .caption.weight(.semibold), valueFont: Font = .caption, labelColor: Color = .secondary, valueColor: Color = .primary) -> AttributedString {
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
                            .accessibilityLabel("Explanation: \(explanation)")
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
                            .accessibilityLabel("Example: \(example)")
                        }

                        if let synonyms = word.synonyms, !synonyms.isEmpty {
                            let synonymsText = synonyms.joined(separator: ", ")
                            Text(
                                attributedText(
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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WordProgress.self, configurations: config)
    NavigationStack {
        FavoritesView()
            .environmentObject(DataService())
    }
    .modelContainer(container)
}
