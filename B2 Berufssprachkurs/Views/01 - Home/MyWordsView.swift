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
        autocapitalize: TextInputAutocapitalization? = nil
    ) -> some View {
        if let style = autocapitalize {
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(1...)
                .fixedSize(horizontal: false, vertical: true)
                .textInputAutocapitalization(style)
        } else {
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(1...)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct MyWordFormFields: View {
    @Binding var german: String
    @Binding var translation: String
    @Binding var example: String
    @Binding var explanation: String

    var body: some View {
        SwiftUI.Section {
            MyWordFormFieldHelpers.multilineField(
                Localizable.string(Localizable.myWordsWordOrPhrase),
                text: $german,
                autocapitalize: .sentences
            )

            MyWordFormFieldHelpers.multilineField(Localizable.string(Localizable.translation), text: $translation)

            MyWordFormFieldHelpers.multilineField(Localizable.string(Localizable.myWordsExampleLabel), text: $example)

            MyWordFormFieldHelpers.multilineField(Localizable.string(Localizable.explanation), text: $explanation)
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
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            // Trailing order: edit (inner), then share (outermost).
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.shared.lightImpact()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        editMode = editMode == .active ? .inactive : .active
                    }
                } label: {
                    Image(systemName: editMode == .active ? "checkmark" : "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(editMode == .active ? Color.accentColor : .primary)
                }
                .accessibilityLabel(
                    Localizable.string(editMode == .active ? Localizable.myWordsDoneEditing : Localizable.myWordsEdit)
                )
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
                                Button {
                                    HapticManager.shared.lightImpact()
                                    editingEntry = entry
                                } label: {
                                    MyWordRow(
                                        word: word,
                                        isFavorite: dataService.isFavorite(wordId: word.id),
                                        onFavoriteToggle: {
                                            HapticManager.shared.lightImpact()
                                            dataService.toggleFavorite(wordId: word.id)
                                        }
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                MyWordRow(
                                    word: word,
                                    isFavorite: dataService.isFavorite(wordId: word.id),
                                    onFavoriteToggle: {
                                        HapticManager.shared.lightImpact()
                                        dataService.toggleFavorite(wordId: word.id)
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
                                ? "Adds a new word to your list"
                                : "Upgrade to Premium to add more than five words"
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
                        .font(.system(.headline, design: .rounded).weight(.semibold))
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
                    explanation: $explanation
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
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(Localizable.string(Localizable.cancel))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(canSave ? Color.accentColor : .secondary)
                    }
                    .disabled(!canSave)
                    .accessibilityLabel(Localizable.string(Localizable.ok))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
}

// MARK: - Edit word sheet

private struct EditMyWordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

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
                    explanation: $explanation
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
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(Localizable.string(Localizable.cancel))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(canSave ? Color.accentColor : .secondary)
                    }
                    .disabled(!canSave)
                    .accessibilityLabel(Localizable.string(Localizable.ok))
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
}

// MARK: - Row (translation as plain text)

struct MyWordRow: View {
    let word: Word
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void

    private func attributedText(
        label: String,
        value: String,
        labelFont: Font = .caption.weight(.semibold),
        valueFont: Font = .caption,
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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isFavorite ? Color("AppYellow") : .secondary)
                    .symbolEffect(.bounce, value: isFavorite)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
            .accessibilityValue(isFavorite ? "Favorited" : "Not favorited")
            .accessibilityHint("Toggle favorite for \(word.german)")
            .accessibilityAddTraits(isFavorite ? .isSelected : [])

            VStack(alignment: .leading, spacing: 4) {
                Text(word.german)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundColor(.primary)

                if let ex = word.example, !ex.isEmpty {
                    Text(ex)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 6) {
                let trimmedTranslation = word.translation.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedTranslation.isEmpty {
                    Text(trimmedTranslation)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Translation: \(trimmedTranslation)")
                }

                if let explanation = word.explanation, !explanation.isEmpty {
                    Text(attributedText(label: "erkl: ", value: explanation))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Explanation: \(explanation)")
                }
            }
            .frame(width: 150, alignment: .leading)
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
