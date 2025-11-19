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
    
    var words: [Word] {
        dataService.getWords(for: sectionId)
    }
    
    var allChecked: Bool {
        !words.isEmpty && words.allSatisfy { dataService.isWordChecked(wordId: $0.id, in: sectionId) }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Check all header
                if !words.isEmpty {
                    HStack {
                        Button(action: {
                            if allChecked {
                                // Uncheck all words
                                for word in words {
                                    dataService.toggleWordChecked(wordId: word.id, in: sectionId)
                                }
                            } else {
                                // Check all words
                                for word in words {
                                    if !dataService.isWordChecked(wordId: word.id, in: sectionId) {
                                        dataService.toggleWordChecked(wordId: word.id, in: sectionId)
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: allChecked ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(allChecked ? Color("AppGreen") : .secondary)
                                
                                Text(Localizable.string(Localizable.selectAll))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                // Words list
                ForEach(words) { word in
                    WordRow(
                        word: word,
                        sectionId: sectionId,
                        isChecked: dataService.isWordChecked(wordId: word.id, in: sectionId),
                        translation: translations[word.id] ?? word.translation,
                        dataService: dataService,
                        onCheckToggle: {
                            dataService.toggleWordChecked(wordId: word.id, in: sectionId)
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
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Initialize translations from dataService
            for word in words {
                if !word.translation.isEmpty {
                    translations[word.id] = word.translation
                }
            }
        }
    }
}

struct WordRow: View {
    let word: Word
    let sectionId: String
    let isChecked: Bool
    let translation: String
    @ObservedObject var dataService: DataService
    let onCheckToggle: () -> Void
    let onTranslationChange: (String) -> Void
    
    @State private var localTranslation: String = ""
    @FocusState private var isTranslationFocused: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkmark on the left
            Button(action: onCheckToggle) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isChecked ? Color("AppGreen") : .secondary)
            }
            .buttonStyle(.plain)
            
            // German word
            VStack(alignment: .leading, spacing: 4) {
                Text(word.german)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Translation input field on the right
            TextField(Localizable.string(Localizable.translation), text: $localTranslation)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 15))
                .frame(width: 150)
                .focused($isTranslationFocused)
                .onAppear {
                    localTranslation = translation
                }
                .onChange(of: localTranslation) { oldValue, newValue in
                    onTranslationChange(newValue)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
    }
}

#Preview {
    NavigationStack {
        WordsListView(sectionId: "1A")
            .environmentObject(DataService())
    }
}
