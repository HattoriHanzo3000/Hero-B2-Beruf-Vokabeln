//
//  WordsListView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct WordsListView: View {
    let sectionId: String
    @EnvironmentObject var dataService: DataService
    @State private var translations: [String: String] = [:]
    @State private var navigateToStudy = false
    @State private var navigateToSettings = false
    @State private var showShareSheet = false
    @FocusState private var focusedWordId: String?
    
    var words: [Word] {
        dataService.getWords(for: sectionId)
    }
    
    var headerInfo: (lectionTitle: String, sectionTitle: String, lectionNumber: String, sectionLetter: String)? {
        dataService.getLectionAndSection(for: sectionId)
    }
    
    var hasAnyWordFavorited: Bool {
        !words.isEmpty && words.contains { dataService.isFavorite(wordId: $0.id) }
    }
    
    var isVerbenSection: Bool {
        sectionId.hasPrefix("VERBEN_")
    }
    
    var isAdjektiveSection: Bool {
        sectionId.hasPrefix("ADJEKTIVE_")
    }
    
    // Determine which stack this belongs to and get appropriate styling
    var stackInfo: (color: Color, icon: String, title: String) {
        if isVerbenSection {
            return (Color("AppBlue"), "square.stack.3d.up.fill", Localizable.string(Localizable.verbsWithPrepositions))
        }
        if isAdjektiveSection {
            return (Color("AppPurple"), "square.stack.3d.up.fill", Localizable.string(Localizable.adjectivesWithPrepositions))
        }
        // For general words sections (default)
        return (Color("AppGreen"), "square.stack.3d.up.fill", Localizable.string(Localizable.generalWords))
    }
    
    // Get preposition title for verben and adjektive sections
    var prepositionTitle: String {
        if isVerbenSection || isAdjektiveSection {
            // Extract preposition from sectionId (e.g., "VERBEN_an" -> "an", "ADJEKTIVE_an" -> "an")
            let parts = sectionId.split(separator: "_")
            if parts.count > 1 {
                return String(parts[1])
            }
        }
        return ""
    }
    
    var body: some View {
        ZStack {
            stackInfo.color.opacity(0.08)
                .ignoresSafeArea()
            
            // Scrollable content including header with Üben button at bottom
            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                    List {
                    // Header matching GeneralWordsView style (now scrollable)
                    if isVerbenSection || isAdjektiveSection {
                        // For verben and adjektive sections, show stack title and preposition (no "general words" title)
                        SwiftUI.Section {
                            EmptyView()
                        } header: {
                            WordsListHeaderView(
                                stackColor: stackInfo.color,
                                stackIcon: stackInfo.icon,
                                stackTitle: stackInfo.title,
                                lectionTitle: "",
                                sectionTitle: prepositionTitle,
                                lectionNumber: "",
                                sectionLetter: ""
                            )
                        }
                    } else if let info = headerInfo {
                        // For general words sections, show both titles
                        SwiftUI.Section {
                            EmptyView()
                        } header: {
                            WordsListHeaderView(
                                stackColor: stackInfo.color,
                                stackIcon: stackInfo.icon,
                                stackTitle: stackInfo.title,
                                lectionTitle: info.lectionTitle,
                                sectionTitle: info.sectionTitle,
                                lectionNumber: info.lectionNumber,
                                sectionLetter: info.sectionLetter
                            )
                        }
                    }
                    
                    // Words list directly in scrollable area
                    ForEach(words) { word in
                        WordRow(
                            word: word,
                            sectionId: sectionId,
                            isFavorite: dataService.isFavorite(wordId: word.id),
                            translation: translations[word.id] ?? word.translation,
                            dataService: dataService,
                            focusedWordId: $focusedWordId,
                            onFavoriteToggle: {
                                HapticManager.shared.lightImpact()
                                dataService.toggleFavorite(wordId: word.id)
                            },
                            onTranslationChange: { newTranslation in
                                translations[word.id] = newTranslation
                                dataService.updateTranslation(
                                    for: word.id,
                                    in: sectionId,
                                    translation: newTranslation
                                )
                            }
                        )
                        .id(word.id)
                        .listRowBackground(Color.clear)
                    }
                }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.top, 8, for: .scrollContent)
                    .contentMargins(.bottom, 150, for: .scrollContent) // Space for button + banner ad
                    .accessibilityLabel("Words list")
                    .accessibilityHint("List of German words with translations, explanations, and synonyms")
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
                                    .fill(stackInfo.color)
                            )
                            .shadow(color: stackInfo.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    
                    // Fixed Banner Ad at the bottom
                    BannerAd()
                        .background(stackInfo.color.opacity(0.08))
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationDestination(isPresented: $navigateToStudy) {
            StudyView(
                dataService: dataService,
                filterBySectionId: sectionId, // From section view: only this section
                studyAllMode: true // Always study all words in section
            )
            .environmentObject(dataService)
        }
        .fullScreenCover(isPresented: $navigateToSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(dataService)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.shared.lightImpact()
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Share")
                .accessibilityHint("Share the words list")
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
                .disabled(focusedWordId == nil || getCurrentWordIndex() == nil || getCurrentWordIndex()! >= words.count - 1)
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
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [generateShareText(), generatePDF()])
        }
        .onAppear {
            // Initialize translations from dataService
            for word in words {
                if !word.translation.isEmpty {
                    translations[word.id] = word.translation
                }
            }
        }
    }
    
    private func generateShareText() -> String {
        var shareText = ""
        
        if let info = headerInfo {
            shareText += "\(info.lectionTitle) - \(info.sectionTitle)\n\n"
        } else if isVerbenSection || isAdjektiveSection {
            shareText += "\(prepositionTitle)\n\n"
        }
        
        for word in words {
            shareText += "\(word.german)"
            if let explanation = word.explanation, !explanation.isEmpty {
                shareText += " (\(explanation))"
            }
            if let translation = translations[word.id], !translation.isEmpty {
                shareText += " - \(translation)"
            } else if !word.translation.isEmpty {
                shareText += " - \(word.translation)"
            }
            shareText += "\n"
        }
        
        return shareText
    }
    
    private func generatePDF() -> URL {
        let lectionTitle: String
        let lectionNumber: String?
        let sectionTitle: String
        let sectionLetter: String?
        
        if let info = headerInfo {
            lectionTitle = info.lectionTitle
            lectionNumber = info.lectionNumber.isEmpty ? nil : info.lectionNumber
            sectionTitle = info.sectionTitle
            sectionLetter = info.sectionLetter.isEmpty ? nil : info.sectionLetter
        } else if isVerbenSection || isAdjektiveSection {
            lectionTitle = stackInfo.title
            lectionNumber = nil
            sectionTitle = prepositionTitle
            sectionLetter = nil
        } else {
            lectionTitle = stackInfo.title
            lectionNumber = nil
            sectionTitle = ""
            sectionLetter = nil
        }
        
        let wordData = words.map { word in
            PDFGenerationService.WordData(
                german: word.german,
                example: word.example,
                explanation: word.explanation,
                translation: translations[word.id] ?? word.translation,
                synonyms: word.synonyms
            )
        }
        
        let pdfInfo = PDFGenerationService.PDFInfo(
            lectionTitle: lectionTitle,
            lectionNumber: lectionNumber,
            sectionTitle: sectionTitle,
            sectionLetter: sectionLetter,
            headerColor: stackInfo.color,
            words: wordData,
            fileName: "WordsList_\(sectionId)"
        )
        
        return PDFGenerationService.generateWordsListPDF(info: pdfInfo)
    }
    
    private func getCurrentWordIndex() -> Int? {
        guard let focusedId = focusedWordId,
              let index = words.firstIndex(where: { $0.id == focusedId }) else {
            return nil
        }
        return index
    }
    
    private func navigateToPreviousField() {
        guard let currentIndex = getCurrentWordIndex(),
              currentIndex > 0 else { return }
        let previousWordId = words[currentIndex - 1].id
        focusedWordId = previousWordId
        // Scrolling is handled by onChange(of: focusedWordId)
    }
    
    private func navigateToNextField() {
        guard let currentIndex = getCurrentWordIndex(),
              currentIndex < words.count - 1 else { return }
        let nextWordId = words[currentIndex + 1].id
        focusedWordId = nextWordId
        // Scrolling is handled by onChange(of: focusedWordId)
    }
    
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct WordRow: View {
    let word: Word
    let sectionId: String
    let isFavorite: Bool
    let translation: String
    @ObservedObject var dataService: DataService
    @FocusState.Binding var focusedWordId: String?
    let onFavoriteToggle: () -> Void
    let onTranslationChange: (String) -> Void
    
    @State private var localTranslation: String = ""
    
    private func attributedText(label: String, value: String, labelFont: Font = .system(.caption, design: .rounded).weight(.semibold), valueFont: Font = .system(.caption, design: .rounded), labelColor: Color = .secondary, valueColor: Color = .primary) -> AttributedString {
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
                        localTranslation = translation
                    }
                    .onChange(of: localTranslation) { oldValue, newValue in
                        onTranslationChange(newValue)
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

// MARK: - Words List Header View
struct WordsListHeaderView: View {
    let stackColor: Color
    let stackIcon: String
    let stackTitle: String
    let lectionTitle: String
    let sectionTitle: String
    let lectionNumber: String
    let sectionLetter: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(stackColor)
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.25), lineWidth: 0.6)
                    )
                Image(systemName: stackIcon)
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(stackTitle)
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)
                
                // Show titles: for verben show only section (preposition), for general show both
                if !lectionTitle.isEmpty && !sectionTitle.isEmpty {
                    // Show both lection and section for general words with numbers/letters
                    HStack(spacing: 8) {
                        if !lectionNumber.isEmpty {
                            Text(lectionNumber)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        Text(lectionTitle)
                            .font(.system(.title3, design: .rounded).weight(.medium))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 8) {
                        if !sectionLetter.isEmpty {
                            Text(sectionLetter.uppercased())
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        Text(sectionTitle)
                            .font(.system(.headline, design: .rounded).weight(.medium))
                            .foregroundColor(.primary)
                    }
                } else if !sectionTitle.isEmpty {
                    // Show only section/preposition title
                    Text(sectionTitle)
                        .font(.system(.headline, design: .rounded).weight(.medium))
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 16)
    }
}

#Preview {
    NavigationStack {
        WordsListView(sectionId: "1A")
            .environmentObject(DataService())
    }
}
