//
//  WordWallpaperBackground.swift
//  B2 Berufssprachkurs
//
//  Diagonal gray word texture behind home and cockpit (bundled vocabulary sample).
//

import SwiftUI

struct WordWallpaperBackground: View {
    @ObservedObject var dataService: DataService
    @State private var words: [String] = []

    private let fontSize: CGFloat = 18
    private let lineSpacing: CGFloat = 24

    var body: some View {
        GeometryReader { geometry in
            let screenDiagonal = sqrt(geometry.size.width * geometry.size.width + geometry.size.height * geometry.size.height)
            let contentWidth = screenDiagonal * 3.0
            let contentHeight = screenDiagonal * 3.0

            Text(words.joined(separator: " "))
                .font(.system(size: fontSize, weight: .medium, design: .default))
                .foregroundColor(Color.gray.opacity(0.12))
                .lineSpacing(lineSpacing)
                .frame(width: contentWidth, alignment: .leading)
                .padding(.horizontal, 40)
                .padding(.vertical, 60)
                .frame(width: contentWidth, height: contentHeight, alignment: .topLeading)
                .rotationEffect(.degrees(-45), anchor: .center)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .clipped()
        .onAppear {
            loadRandomWords()
        }
        .onChange(of: dataService.wordsBySection) { _, _ in
            loadRandomWords()
        }
    }

    private func loadRandomWords() {
        var allWords: [String] = []

        for (_, wordList) in dataService.wordsBySection {
            for word in wordList {
                if !word.german.isEmpty {
                    allWords.append(word.german)
                }
            }
        }

        let shuffled = allWords.shuffled()
        if shuffled.count >= 800 {
            words = Array(shuffled.prefix(800))
        } else {
            var repeatedWords: [String] = []
            while repeatedWords.count < 800 {
                repeatedWords.append(contentsOf: shuffled)
            }
            words = Array(repeatedWords.prefix(800))
        }
    }
}
