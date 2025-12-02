//
//  FavoritesView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToStudy = false
    @State private var translations: [String: String] = [:]
    @FocusState private var focusedWordId: String?
    
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
        NavigationStack {
            ZStack {
                Color.yellow.opacity(0.08)
                    .ignoresSafeArea()
                
                // Scrollable content including header with Üben button at bottom
                if favoriteWords.isEmpty {
                    // Empty state view
                    VStack(spacing: 0) {
                        // Header with close button
                        HStack {
                            Spacer()
                            
                            Text(Localizable.string(Localizable.favorites))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .accessibilityAddTraits(.isHeader)
                            
                            Spacer()
                            
                            Button {
                                HapticManager.shared.lightImpact()
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(liquidGlassCircle)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .accessibilityLabel("Close")
                            .accessibilityHint("Close this view")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        Spacer()
                        
                        // Empty state content
                        VStack(spacing: 20) {
                            Image(systemName: "star")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                            
                            Text(Localizable.string(Localizable.noFavoritesFound))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text(Localizable.string(Localizable.noFavoritesFoundMessage))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .accessibilityElement(children: .combine)
                        
                        Spacer()
                    }
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        navigateToPreviousField()
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .disabled(focusedWordId == nil || getCurrentWordIndex() == nil || getCurrentWordIndex()! <= 0)
                    .accessibilityLabel("Previous word")
                    .accessibilityHint("Navigate to the previous word in the list")
                    
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        navigateToNextField()
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .disabled(focusedWordId == nil || getCurrentWordIndex() == nil || getCurrentWordIndex()! >= favoriteWords.count - 1)
                    .accessibilityLabel("Next word")
                    .accessibilityHint("Navigate to the next word in the list")
                    
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        focusedWordId = nil
                    }) {
                        Text("Done")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Hide keyboard and finish input")
                }
            }
            .onAppear {
                // Initialize translations from dataService
                for word in favoriteWords {
                    if !word.translation.isEmpty {
                        translations[word.id] = word.translation
                    }
                }
            }
            .onChange(of: favoriteWords) { _, _ in
                // Update translations when favorites change
                for word in favoriteWords {
                    if !word.translation.isEmpty {
                        translations[word.id] = word.translation
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var favoritesListView: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                List {
                    // Header matching WordsListView style (scrollable)
                    SwiftUI.Section {
                        EmptyView()
                    } header: {
                        FavoritesHeaderView()
                    }
                    
                    // Favorites words list
                    ForEach(favoriteWords) { word in
                        FavoriteWordRow(
                            word: word,
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
                                // Find sectionId for this word
                                for (sectionId, words) in dataService.wordsBySection {
                                    if words.contains(where: { $0.id == word.id }) {
                                        dataService.updateTranslation(
                                            for: word.id,
                                            in: sectionId,
                                            translation: newTranslation
                                        )
                                        break
                                    }
                                }
                            }
                        )
                        .id(word.id)
                        .listRowBackground(Color.clear)
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
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.yellow)
                        )
                        .shadow(color: Color.yellow.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                
                // Fixed Banner Ad at the bottom
                BannerAd()
                    .background(Color.yellow.opacity(0.08))
            }
        }
    }
    
    private var liquidGlassCircle: some View {
        Circle()
            .fill(.regularMaterial)
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .overlay {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Favorites Header View
struct FavoritesHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    
    private var liquidGlassCircle: some View {
        Circle()
            .fill(.regularMaterial)
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.4),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .overlay {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.yellow)
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.25), lineWidth: 0.6)
                    )
                Image(systemName: "star.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
            }
            
            Text(Localizable.string(Localizable.favorites))
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button {
                HapticManager.shared.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(liquidGlassCircle)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Close")
            .accessibilityHint("Close this view")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 16)
    }
}

// MARK: - Favorite Word Row
struct FavoriteWordRow: View {
    let word: Word
    let isFavorite: Bool
    let translation: String
    @ObservedObject var dataService: DataService
    @FocusState.Binding var focusedWordId: String?
    let onFavoriteToggle: () -> Void
    let onTranslationChange: (String) -> Void
    
    @State private var localTranslation: String = ""
    
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isFavorite ? Color.yellow : .secondary)
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
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let example = word.example, !example.isEmpty {
                    Text(example)
                        .font(.subheadline)
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
                    .font(.subheadline)
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

#Preview {
    FavoritesView()
        .environmentObject(DataService())
}
