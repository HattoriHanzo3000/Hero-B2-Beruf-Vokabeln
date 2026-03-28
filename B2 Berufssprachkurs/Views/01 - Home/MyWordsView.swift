//
//  MyWordsView.swift
//  B2 Berufssprachkurs
//
//  Personal vocabulary list; entries are SwiftData + CloudKit (same container as WordProgress).
//

import SwiftUI
import SwiftData

// MARK: - Shared form fields (add + edit sheet)

private enum MyWordFormFieldHelpers {
    @ViewBuilder
    static func multilineField(
        _ placeholder: String,
        text: Binding<String>,
        focusedField: FocusState<MyWordSheetField?>.Binding,
        field: MyWordSheetField,
        autocapitalize: TextInputAutocapitalization? = nil
    ) -> some View {
        if let style = autocapitalize {
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(1...)
                .fixedSize(horizontal: false, vertical: true)
                .textInputAutocapitalization(style)
                .focused(focusedField, equals: field)
        } else {
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(1...)
                .fixedSize(horizontal: false, vertical: true)
                .focused(focusedField, equals: field)
        }
    }
}

private enum MyWordSheetField: Int, CaseIterable {
    case german
    case translation
    case example
    case explanation

    var previous: Self? {
        guard rawValue > 0 else { return nil }
        return Self(rawValue: rawValue - 1)
    }

    var next: Self? {
        Self(rawValue: rawValue + 1)
    }
}

private struct MyWordFormFields: View {
    @Binding var german: String
    @Binding var translation: String
    @Binding var example: String
    @Binding var explanation: String
    let focusedField: FocusState<MyWordSheetField?>.Binding

    var body: some View {
        SwiftUI.Section {
            MyWordFormFieldHelpers.multilineField(
                Localizable.string(Localizable.myWordsWordOrPhrase),
                text: $german,
                focusedField: focusedField,
                field: .german,
                autocapitalize: .never
            )

            MyWordFormFieldHelpers.multilineField(
                Localizable.string(Localizable.translation),
                text: $translation,
                focusedField: focusedField,
                field: .translation,
                autocapitalize: .never
            )

            MyWordFormFieldHelpers.multilineField(
                Localizable.string(Localizable.myWordsExampleLabel),
                text: $example,
                focusedField: focusedField,
                field: .example,
                autocapitalize: .never
            )

            MyWordFormFieldHelpers.multilineField(
                Localizable.string(Localizable.explanation),
                text: $explanation,
                focusedField: focusedField,
                field: .explanation,
                autocapitalize: .never
            )
        }
    }
}

struct MyWordsView: View {
    @EnvironmentObject private var dataService: DataService
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Query(sort: [
        SortDescriptor(\CustomWordEntry.sortIndex, order: .forward),
        SortDescriptor(\CustomWordEntry.createdAt, order: .forward)
    ]) private var customWordEntries: [CustomWordEntry]

    @State private var showAddWordSheet = false
    @State private var navigateToStudy = false
    @State private var editMode: EditMode = .inactive
    @State private var editingEntry: CustomWordEntry?
    @State private var showShareSheet = false
    @State private var showPaywall = false
    @State private var showDeleteAllConfirmation = false

    private var accent: Color { Color("AppRed") }

    /// Free users may add up to `CustomWordEntry.FreeTier.maxWords` entries; premium is unlimited.
    private var canAddMoreMyWords: Bool {
        subscriptionManager.isPremiumActive || customWordEntries.count < CustomWordEntry.FreeTier.maxWords
    }

    var body: some View {
        ZStack {
            accent.opacity(0.08)
                .ignoresSafeArea()

            myWordsListView
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            // Trailing order: edit (inner), delete-all when editing (middle), share (outermost).
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.shared.lightImpact()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        editMode = editMode == .active ? .inactive : .active
                    }
                } label: {
                    Image(systemName: editMode == .active ? "checkmark" : "pencil")
                        .navigationBarSymbolStyle()
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel(
                    Localizable.string(editMode == .active ? Localizable.myWordsDoneEditing : Localizable.myWordsEdit)
                )
            }
            if editMode == .active, !customWordEntries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.shared.heavyImpact()
                        showDeleteAllConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .navigationBarSymbolStyle()
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel(Localizable.string(Localizable.myWordsDeleteAllToolbarLabel))
                    .accessibilityHint(Localizable.string(Localizable.myWordsDeleteAllToolbarHint))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                WordListShareButton(showShareSheet: $showShareSheet, showPaywall: $showPaywall)
            }
        }
        .wordListPremiumShareSheets(
            showShareSheet: $showShareSheet,
            showPaywall: $showPaywall,
            shareText: { generateShareText() },
            pdfURL: { generateMyWordsPDF() }
        )
        .sheet(isPresented: $showAddWordSheet) {
            AddMyWordSheet(
                onLimitReached: {
                    showPaywall = true
                }
            )
        }
        .sheet(item: $editingEntry) { entry in
            EditMyWordSheet(entry: entry)
        }
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                dataService: dataService,
                filterBySectionId: DataService.userMyWordsSectionId,
                studyAllMode: true,
                favoritesOnly: false,
                categoryFilter: nil
            )
            .environmentObject(dataService)
        }
        .onAppear {
            CustomWordEntry.renumberSortOrderIfNeeded(in: modelContext)
        }
        .alert(
            Localizable.string(Localizable.myWordsDeleteAllTitle),
            isPresented: $showDeleteAllConfirmation
        ) {
            Button(Localizable.string(Localizable.cancel), role: .cancel) {}
            Button(Localizable.string(Localizable.myWordsDeleteAllConfirm), role: .destructive) {
                deleteAllMyWords()
            }
        } message: {
            Text(Localizable.string(Localizable.myWordsDeleteAllMessage))
        }
        .hidesBottomBarWhenPushed(true)
    }

    private func generateShareText() -> String {
        let title = Localizable.string(Localizable.myWords).replacingOccurrences(of: "\n", with: " ")
        let words = customWordEntries.map { $0.asWord() }
        return WordListShareManager.shareText(
            words: words,
            header: "\(title)\n\n",
            translationProvider: { word in
                word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        )
    }

    private func generateMyWordsPDF() -> URL {
        let words = customWordEntries.map { $0.asWord() }
        let wordData = WordListShareManager.wordDataForPDF(
            words: words,
            translationProvider: { word in
                word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        )
        let myWordsTitle = Localizable.string(Localizable.myWords).replacingOccurrences(of: "\n", with: " ")
        let pdfInfo = PDFGenerationService.PDFInfo(
            lectionTitle: myWordsTitle,
            lectionNumber: nil,
            sectionTitle: "",
            sectionLetter: nil,
            headerColor: Color("AppRed"),
            words: wordData,
            fileName: "MyWords"
        )
        return PDFGenerationService.generateWordsListPDF(info: pdfInfo)
    }

    private var myWordsListView: some View {
        ZStack(alignment: .bottom) {
            List {
                SwiftUI.Section {
                    EmptyView()
                } header: {
                    ScrollableStackRootHeader(
                        accent: accent,
                        icon: "text.book.closed.fill",
                        title: Localizable.string(Localizable.myWords).replacingOccurrences(of: "\n", with: " "),
                        showsDivider: false
                    )
                }

                SwiftUI.Section {
                    ForEach(customWordEntries) { entry in
                        let word = entry.asWord()
                        Group {
                            if editMode == .active {
                                myWordEditModeRow(entry: entry, word: word)
                            } else {
                                MyWordRow(
                                    word: word,
                                    isFavorite: dataService.isFavorite(wordId: word.id),
                                    onEditTranslation: { editingEntry = entry },
                                    onFavoriteToggle: {
                                        if dataService.toggleFavorite(wordId: word.id) {
                                            HapticManager.shared.lightImpact()
                                        } else {
                                            HapticManager.shared.heavyImpact()
                                            showPaywall = true
                                        }
                                    }
                                )
                            }
                        }
                        .id(entry.id)
                        .listRowBackground(Color.clear)
                    }
                    .onMove(perform: applyMove)

                    if editMode == .inactive {
                        if !subscriptionManager.isPremiumActive {
                            Text(
                                String(
                                    format: Localizable.string(Localizable.myWordsFreePlanFooter),
                                    customWordEntries.count,
                                    CustomWordEntry.FreeTier.maxWords
                                )
                            )
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden, edges: .bottom)
                            .accessibilityLabel(
                                String(
                                    format: Localizable.string(Localizable.myWordsFreePlanFooter),
                                    customWordEntries.count,
                                    CustomWordEntry.FreeTier.maxWords
                                )
                            )
                        }

                        Button {
                            if canAddMoreMyWords {
                                HapticManager.shared.lightImpact()
                                showAddWordSheet = true
                            } else {
                                HapticManager.shared.heavyImpact()
                                showPaywall = true
                            }
                        } label: {
                            HStack {
                                Spacer(minLength: 0)
                                Image(systemName: canAddMoreMyWords ? "plus.circle.fill" : "lock.circle.fill")
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                                    .foregroundStyle(canAddMoreMyWords ? accent : .secondary)
                                    .symbolRenderingMode(.hierarchical)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden, edges: .bottom)
                        .accessibilityLabel(Localizable.string(Localizable.myWordsAddWord))
                        .accessibilityHint(
                            canAddMoreMyWords
                                ? Localizable.string(Localizable.myWordsAddWordA11yHint)
                                : Localizable.string(Localizable.myWordsAddWordA11yHintLocked)
                        )
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 8, for: .scrollContent)
            .contentMargins(.bottom, 90, for: .scrollContent)
            .accessibilityLabel("My Words list")
            .accessibilityHint("Your personal words; add a word with the button at the bottom of the list")

            VStack(spacing: 0) {
                Button {
                    HapticManager.shared.mediumImpact()
                    navigateToStudy = true
                } label: {
                    Text(Localizable.string(Localizable.practice))
                        .font(.system(.headline, design: .default, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            Capsule(style: .continuous)
                                .fill(accent)
                        )
                        .shadow(color: accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(customWordEntries.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    private func myWordEditModeRow(entry: CustomWordEntry, word: Word) -> some View {
        MyWordRow(
            word: word,
            isFavorite: dataService.isFavorite(wordId: word.id),
            onEditTranslation: {},
            onFavoriteToggle: {},
            onDelete: { deleteEntry(entry) },
            openEditSheet: {
                HapticManager.shared.lightImpact()
                editingEntry = entry
            },
            translationButtonsEnabled: false
        )
        .accessibilityHint(Localizable.string(Localizable.myWordsEditRowHint))
    }

    private func deleteAllMyWords() {
        let entries = Array(customWordEntries)
        guard !entries.isEmpty else { return }

        for entry in entries {
            let wordId = entry.id
            if dataService.isFavorite(wordId: wordId) {
                dataService.toggleFavorite(wordId: wordId)
            }
            let wid = wordId
            var progressDescriptor = FetchDescriptor<WordProgress>(
                predicate: #Predicate<WordProgress> { $0.wordId == wid }
            )
            progressDescriptor.fetchLimit = 1
            if let progress = try? modelContext.fetch(progressDescriptor).first {
                modelContext.delete(progress)
            }
            modelContext.delete(entry)
        }

        editingEntry = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            editMode = .inactive
        }
        try? modelContext.save()
        HapticManager.shared.mediumImpact()
    }

    private func deleteEntry(_ entry: CustomWordEntry) {
        let wordId = entry.id
        if dataService.isFavorite(wordId: wordId) {
            dataService.toggleFavorite(wordId: wordId)
        }
        if editingEntry?.id == entry.id {
            editingEntry = nil
        }
        let wid = wordId
        var progressDescriptor = FetchDescriptor<WordProgress>(
            predicate: #Predicate<WordProgress> { $0.wordId == wid }
        )
        progressDescriptor.fetchLimit = 1
        if let progress = try? modelContext.fetch(progressDescriptor).first {
            modelContext.delete(progress)
        }
        modelContext.delete(entry)
        try? modelContext.save()
        HapticManager.shared.mediumImpact()
    }

    private func applyMove(from source: IndexSet, to destination: Int) {
        var ordered = customWordEntries
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, entry) in ordered.enumerated() {
            entry.sortIndex = i
        }
        try? modelContext.save()
        HapticManager.shared.lightImpact()
    }
}

// MARK: - Add word sheet

private struct AddMyWordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @FocusState private var focusedField: MyWordSheetField?
    @StateObject private var keyboardNavBridge = WordListKeyboardNavBridge()

    /// Called when save is blocked because the free tier is full (e.g. race); presents paywall from parent.
    var onLimitReached: () -> Void = {}

    @State private var german = ""
    @State private var translation = ""
    @State private var example = ""
    @State private var explanation = ""

    private var canSave: Bool {
        !german.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                MyWordFormFields(
                    german: $german,
                    translation: $translation,
                    example: $example,
                    explanation: $explanation,
                    focusedField: $focusedField
                )
            }
            .navigationTitle(Localizable.string(Localizable.myWordsAddWord))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .navigationBarSymbolStyle()
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(Localizable.string(Localizable.cancel))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .navigationBarSymbolStyle()
                            .foregroundStyle(canSave ? Color.primary : Color.primary.opacity(0.34))
                    }
                    .disabled(!canSave)
                    .accessibilityLabel(Localizable.string(Localizable.ok))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    TranslationKeyboardNavAccessory(
                        keyboardNav: keyboardNavBridge,
                        onPrevious: {
                            HapticManager.shared.lightImpact()
                            focusPreviousField()
                        },
                        onNext: {
                            HapticManager.shared.lightImpact()
                            focusNextField()
                        },
                        onDone: {
                            HapticManager.shared.lightImpact()
                            focusedField = nil
                        }
                    )
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            syncKeyboardNavBridge()
        }
        .onChange(of: focusedField) { _, _ in
            syncKeyboardNavBridge()
        }
    }

    private func nextSortIndex() -> Int {
        let descriptor = FetchDescriptor<CustomWordEntry>()
        guard let all = try? modelContext.fetch(descriptor) else { return 0 }
        return (all.map(\.sortIndex).max() ?? -1) + 1
    }

    private func saveAndDismiss() {
        let g = german.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !g.isEmpty else { return }

        let existingCount = (try? modelContext.fetch(FetchDescriptor<CustomWordEntry>()))?.count ?? 0
        if !subscriptionManager.isPremiumActive && existingCount >= CustomWordEntry.FreeTier.maxWords {
            HapticManager.shared.heavyImpact()
            dismiss()
            DispatchQueue.main.async {
                onLimitReached()
            }
            return
        }

        let ex = example.trimmingCharacters(in: .whitespacesAndNewlines)
        let exp = explanation.trimmingCharacters(in: .whitespacesAndNewlines)

        let entry = CustomWordEntry(
            german: g,
            translation: translation.trimmingCharacters(in: .whitespacesAndNewlines),
            example: ex.isEmpty ? nil : ex,
            explanation: exp.isEmpty ? nil : exp,
            sortIndex: nextSortIndex()
        )
        modelContext.insert(entry)
        try? modelContext.save()
        HapticManager.shared.lightImpact()
        dismiss()
    }

    private func focusPreviousField() {
        focusedField = focusedField?.previous
    }

    private func focusNextField() {
        focusedField = focusedField?.next
    }

    private func syncKeyboardNavBridge() {
        keyboardNavBridge.syncCanNavigate(
            canPrevious: focusedField?.previous != nil,
            canNext: focusedField?.next != nil
        )
    }
}

// MARK: - Edit word sheet

private struct EditMyWordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var focusedField: MyWordSheetField?
    @StateObject private var keyboardNavBridge = WordListKeyboardNavBridge()

    let entry: CustomWordEntry

    @State private var german = ""
    @State private var translation = ""
    @State private var example = ""
    @State private var explanation = ""

    private var canSave: Bool {
        !german.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                MyWordFormFields(
                    german: $german,
                    translation: $translation,
                    example: $example,
                    explanation: $explanation,
                    focusedField: $focusedField
                )
            }
            .navigationTitle(Localizable.string(Localizable.myWordsEditWord))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .navigationBarSymbolStyle()
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(Localizable.string(Localizable.cancel))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .navigationBarSymbolStyle()
                            .foregroundStyle(canSave ? Color.primary : Color.primary.opacity(0.34))
                    }
                    .disabled(!canSave)
                    .accessibilityLabel(Localizable.string(Localizable.ok))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    TranslationKeyboardNavAccessory(
                        keyboardNav: keyboardNavBridge,
                        onPrevious: {
                            HapticManager.shared.lightImpact()
                            focusPreviousField()
                        },
                        onNext: {
                            HapticManager.shared.lightImpact()
                            focusNextField()
                        },
                        onDone: {
                            HapticManager.shared.lightImpact()
                            focusedField = nil
                        }
                    )
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            german = entry.german
            translation = entry.translation
            example = entry.example ?? ""
            explanation = entry.explanation ?? ""
            syncKeyboardNavBridge()
        }
        .onChange(of: focusedField) { _, _ in
            syncKeyboardNavBridge()
        }
    }

    private func saveAndDismiss() {
        let g = german.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !g.isEmpty else { return }

        let ex = example.trimmingCharacters(in: .whitespacesAndNewlines)
        let exp = explanation.trimmingCharacters(in: .whitespacesAndNewlines)

        entry.german = g
        entry.translation = translation.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.example = ex.isEmpty ? nil : ex
        entry.explanation = exp.isEmpty ? nil : exp

        try? modelContext.save()
        HapticManager.shared.lightImpact()
        dismiss()
    }

    private func focusPreviousField() {
        focusedField = focusedField?.previous
    }

    private func focusNextField() {
        focusedField = focusedField?.next
    }

    private func syncKeyboardNavBridge() {
        keyboardNavBridge.syncCanNavigate(
            canPrevious: focusedField?.previous != nil,
            canNext: focusedField?.next != nil
        )
    }
}

// MARK: - Row (same structure & typography as `WordRow` in `WordsListView`)

private extension View {
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

    @ViewBuilder
    private var translationColumn: some View {
        if trimmedTranslation.isEmpty {
            // Meine Wörter: no pencil — users add/edit translation in the full word sheet, not inline.
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
            .accessibilityLabel("Translation: \(trimmedTranslation)")
            .accessibilityHint("Double tap to edit translation")
        } else {
            Text(trimmedTranslation)
                .font(.system(.subheadline, design: .default, weight: .medium))
                .foregroundColor(translationTextColor)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 96, maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Translation: \(trimmedTranslation)")
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
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            .accessibilityValue(isFavorite ? "Favorited" : "Not favorited")
            .accessibilityHint("Toggle favorite for \(word.german)")
            .accessibilityAddTraits(isFavorite ? .isSelected : [])
        } else {
            Color.clear.frame(width: Self.starColumnWidth, height: 0)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .myWordEditSheetTap(openEditSheet)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Word row for \(word.german)")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WordProgress.self, CustomWordEntry.self, configurations: config)
    NavigationStack {
        MyWordsView()
            .environmentObject(DataService())
    }
    .modelContainer(container)
}
