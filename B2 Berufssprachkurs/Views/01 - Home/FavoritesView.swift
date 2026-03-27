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
    @State private var showShareSheet = false
    @State private var showPaywall = false
    @FocusState private var focusedWordId: String?

    private var progressByWordId: [String: WordProgress] {
        Dictionary(uniqueKeysWithValues: wordProgressList.map { ($0.wordId, $0) })
    }

    private func userTranslation(for wordId: String) -> String {
        progressByWordId[wordId]?.translation ?? ""
    }

    var favoriteWords: [Word] {
        dataService.getFavoriteWords()
    }
    
    private func getCurrentWordIndex() -> Int? {
        guard let focusedId = focusedWordId,
              let index = favoriteWords.firstIndex(where: { $0.id == focusedId }) else {
            return nil
        }
        return index
    }
    
    private func navigateToPreviousField() {
        guard let currentIndex = getCurrentWordIndex(),
              currentIndex > 0 else { return }
        let previousWordId = favoriteWords[currentIndex - 1].id
        focusedWordId = previousWordId
    }
    
    private func navigateToNextField() {
        guard let currentIndex = getCurrentWordIndex(),
              currentIndex < favoriteWords.count - 1 else { return }
        let nextWordId = favoriteWords[currentIndex + 1].id
        focusedWordId = nextWordId
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
                favoritesEmptyStateView
            } else {
                favoritesListView
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
            if favoriteWords.isEmpty {
                ToolbarItem(placement: .principal) {
                    Text(Localizable.string(Localizable.favorites))
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                WordListShareButton(showShareSheet: $showShareSheet, showPaywall: $showPaywall)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button(action: {
                    HapticManager.shared.lightImpact()
                    navigateToPreviousField()
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                }
                .disabled(focusedWordId == nil || getCurrentWordIndex() == nil || getCurrentWordIndex()! <= 0)
                .accessibilityLabel("Previous word")
                .accessibilityHint("Navigate to the previous word in the list")

                Button(action: {
                    HapticManager.shared.lightImpact()
                    navigateToNextField()
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                }
                .disabled(focusedWordId == nil || getCurrentWordIndex() == nil || getCurrentWordIndex()! >= favoriteWords.count - 1)
                .accessibilityLabel("Next word")
                .accessibilityHint("Navigate to the next word in the list")

                Button(action: {
                    HapticManager.shared.lightImpact()
                    focusedWordId = nil
                }) {
                    Text("Done")
                        .font(.system(.callout, design: .rounded).weight(.semibold))
                }
                .accessibilityLabel("Done")
                .accessibilityHint("Hide keyboard and finish input")
            }
        }
        .wordListPremiumShareSheets(
            showShareSheet: $showShareSheet,
            showPaywall: $showPaywall,
            shareText: { generateFavoritesShareText() },
            pdfURL: { generateFavoritesPDF() }
        )
        .hidesBottomBarWhenPushed(true)
    }

    private func generateFavoritesShareText() -> String {
        WordListShareManager.shareText(
            words: favoriteWords,
            header: "\(Localizable.string(Localizable.favorites))\n\n",
            translationProvider: { userTranslation(for: $0.id) }
        )
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
            fileName: "Favorites"
        )
        return PDFGenerationService.generateWordsListPDF(info: pdfInfo)
    }

    private var favoritesEmptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "star")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                Text(Localizable.string(Localizable.noFavoritesFound))
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)

                Text(Localizable.string(Localizable.noFavoritesFoundMessage))
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .accessibilityElement(children: .combine)

            Spacer()
        }
    }
    
    private var favoritesListView: some View {
        ZStack(alignment: .bottom) {
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
                                focusedWordId: $focusedWordId,
                                onFavoriteToggle: {
                                    HapticManager.shared.lightImpact()
                                    dataService.toggleFavorite(wordId: word.id)
                                }
                            )
                            .id(word.id)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, 8, for: .scrollContent)
                .contentMargins(.bottom, 90, for: .scrollContent)
                .accessibilityLabel("Favorites list")
                .accessibilityHint("List of favorite German words with translations, explanations, and synonyms")
                .onChange(of: focusedWordId) { oldValue, newValue in
                    if let wordId = newValue {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(wordId, anchor: .center)
                        }
                    }
                }
            }
            
            // Üben button and Banner Ad at the bottom
            VStack(spacing: 0) {
                // Üben button (always active)
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
                                .fill(Color("AppYellow"))
                        )
                        .shadow(color: Color("AppYellow").opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                
            }
        }
    }
}

// MARK: - Favorite Word Row
struct FavoriteWordRow: View {
    let word: Word
    let isFavorite: Bool
    @ObservedObject var dataService: DataService
    @FocusState.Binding var focusedWordId: String?
    let onFavoriteToggle: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var progressMatches: [WordProgress]
    @State private var localTranslation: String = ""

    init(
        word: Word,
        isFavorite: Bool,
        dataService: DataService,
        focusedWordId: FocusState<String?>.Binding,
        onFavoriteToggle: @escaping () -> Void
    ) {
        self.word = word
        self.isFavorite = isFavorite
        self.dataService = dataService
        self._focusedWordId = focusedWordId
        self.onFavoriteToggle = onFavoriteToggle
        let id = word.id
        _progressMatches = Query(filter: #Predicate<WordProgress> { $0.wordId == id })
    }

    private var cloudTranslation: String {
        progressMatches.first?.translation ?? ""
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
        HStack(alignment: .top, spacing: 12) {
            // Star on the left (yellow when favorited)
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
            
            // German word with example sentence
            VStack(alignment: .leading, spacing: 4) {
                Text(word.german)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundColor(.primary)
                
                if let example = word.example, !example.isEmpty {
                    Text(example)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("German word: \(word.german)\(word.example != nil && !word.example!.isEmpty ? ". Example: \(word.example!)" : "")")
            
            // Translation column on the right with explanation, synonyms, and translation
            VStack(alignment: .leading, spacing: 6) {
                // Row 1: Explanation
                if let explanation = word.explanation, !explanation.isEmpty {
                    Text(attributedText(label: "erkl: ", value: explanation))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Explanation: \(explanation)")
                }
                
                // Row 2: Synonyms
                if let synonyms = word.synonyms, !synonyms.isEmpty {
                    let synonymsText = synonyms.joined(separator: ", ")
                    Text(attributedText(label: "syn: ", value: synonymsText))
                        .accessibilityLabel("Synonyms: \(synonymsText)")
                }
                
                // Row 3: Translation input field
                TextField("Übersetzung", text: $localTranslation, axis: .vertical)
                    .font(.system(.subheadline, design: .rounded))
                    .lineLimit(1...10)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                    )
                    .focused($focusedWordId, equals: word.id)
                    .accessibilityLabel("Translation for \(word.german)")
                    .accessibilityHint("Enter the translation for this German word")
                    .accessibilityValue(localTranslation.isEmpty ? "Empty" : localTranslation)
                    .onAppear {
                        localTranslation = cloudTranslation
                    }
                    .onChange(of: cloudTranslation) { _, newValue in
                        guard focusedWordId != word.id else { return }
                        localTranslation = newValue
                    }
                    .onChange(of: localTranslation) { _, newValue in
                        WordProgress.upsertTranslation(wordId: word.id, text: newValue, in: modelContext)
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
    let container = try! ModelContainer(for: WordProgress.self, configurations: config)
    NavigationStack {
        FavoritesView()
            .environmentObject(DataService())
    }
    .modelContainer(container)
}
