//
//  HeaderView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import UIKit

struct HeaderView: View {
    @ObservedObject var dataService: DataService
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var wordOfTheDay: Word? = nil
    @State private var showMascotGif = false
    @State private var gifPlayToken: UUID = UUID()
    @State private var autoPlayTask: Task<Void, Never>? = nil
    @AppStorage("wordOfTheDayPeriodicity") private var wordOfTheDayPeriodicity = "24_hours"
    @AppStorage("wordOfTheDaySelectedSections") private var wordOfTheDaySelectedSections = ""
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let gifAnimationDuration: Double = 1.1
    private let autoPlayInterval: TimeInterval = 15.0 // Auto-play every 15 seconds
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background that extends to top edge
            LinearGradient(
                colors: [
                    Color("AppGreen"),
                    Color("AppBlue")
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea(edges: .top)
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
            
            // Content that respects safe area
        HStack(alignment: .top, spacing: 5) {
            // Mascot on the left top with animation
            mascotView
                .padding(.top, 4)
            
            // 5 rows of text content
            VStack(alignment: .leading, spacing: 8) {
                // Row 1: "Word of the Day" label
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(.callout, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                    Text(Localizable.string(Localizable.wordOfTheDay))
                        .font(.system(.callout, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                        .id("wordOfTheDayLabel_\(languageManager.currentLanguage)")
                }
                
                // Row 2: Word of the day
                if let word = wordOfTheDay {
                    Text(word.german)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Row 3: Explanation
                    if let explanation = word.explanation, !explanation.isEmpty {
                        Text(attributedText(
                            label: "erkl: ",
                            value: explanation,
                            labelFont: .system(.subheadline, design: .rounded).weight(.bold),
                            valueFont: .system(.subheadline, design: .rounded).weight(.semibold),
                            labelColor: Color("AppYellow")
                        ))
                                .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Row 4: Synonym
                    if let synonyms = word.synonyms, let firstSynonym = synonyms.first {
                        Text(attributedText(
                            label: "syn: ",
                            value: firstSynonym,
                            labelFont: .system(.subheadline, design: .rounded).weight(.bold),
                            valueFont: .system(.subheadline, design: .rounded).weight(.semibold),
                            labelColor: Color("AppYellow")
                        ))
                                .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Row 5: Translation
                    if !word.translation.isEmpty && word.translation.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                        Text(attributedText(
                            label: "übers: ",
                            value: word.translation,
                            labelFont: .system(.subheadline, design: .rounded).weight(.bold),
                            valueFont: .system(.subheadline, design: .rounded).weight(.semibold),
                            labelColor: Color("AppYellow")
                        ))
                                .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Row 6: Example (last row)
                    if let example = word.example, !example.isEmpty {
                        Text(attributedText(
                            label: "beisp: ",
                            value: example,
                            labelFont: .system(.subheadline, design: .rounded).weight(.bold),
                            valueFont: .system(.subheadline, design: .rounded).weight(.semibold),
                            labelColor: Color("AppYellow")
                        ))
                                .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    // Empty state
                    Text(Localizable.string(Localizable.wordOfTheDay))
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
        }
            .padding(.top)
            .padding(.bottom, 18)
            .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            updateWordOfTheDay()
            startAutoPlay()
        }
        .onChange(of: dataService.wordsBySection) { _, _ in
            updateWordOfTheDay()
        }
        .onChange(of: wordOfTheDayPeriodicity) { _, _ in
            updateWordOfTheDay()
        }
        .onChange(of: wordOfTheDaySelectedSections) { _, _ in
            updateWordOfTheDay()
        }
        .onDisappear {
            autoPlayTask?.cancel()
            autoPlayTask = nil
        }
    }
    
    // MARK: - Mascot View
    private var mascotView: some View {
        ZStack {
            // Static image
            Image(staticMascotAssetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .opacity((showMascotGif && !reduceMotion) ? 0 : 1)
            
            // Animated GIF
            AnimatedGIFView(
                gifName: gifMascotAssetName,
                contentMode: .scaleAspectFit,
                shouldAnimate: showMascotGif && !reduceMotion
            )
            .id(gifPlayToken)
            .frame(width: 120, height: 120)
            .opacity((showMascotGif && !reduceMotion) ? 1 : 0)
            .allowsHitTesting(false)
        }
        .frame(width: 120, height: 120)
        .contentShape(Rectangle())
        .onTapGesture {
            playGifOnly()
        }
    }
    
    private var staticMascotAssetName: String {
        if colorScheme == .dark, UIImage(named: "MascotDark") != nil {
            return "MascotDark"
        }
        return "Mascot"
    }
    
    private var gifMascotAssetName: String {
        if colorScheme == .dark, gifExists(named: "MascotDark") {
            return "MascotDark"
        }
        return "Mascot"
    }
    
    private func gifExists(named name: String) -> Bool {
        let subdirectories: [String?] = [nil, "02 - Gifs", "GIFs", "Resources/02 - Gifs"]
        for subdirectory in subdirectories {
            if Bundle.main.url(forResource: name, withExtension: "gif", subdirectory: subdirectory) != nil {
                return true
            }
        }
        return false
    }
    
    private func playGifOnly() {
        guard !reduceMotion else { return }
        gifPlayToken = UUID()
        showMascotGif = true
        DispatchQueue.main.asyncAfter(deadline: .now() + gifAnimationDuration) {
            showMascotGif = false
        }
    }
    
    private func updateWordOfTheDay() {
        wordOfTheDay = dataService.getWordOfTheDay()
    }
    
    private func attributedText(label: String, value: String, labelFont: Font = .system(.subheadline, design: .rounded).weight(.semibold), valueFont: Font = .system(.subheadline, design: .rounded).weight(.semibold), labelColor: Color? = nil) -> AttributedString {
        var fullText = AttributedString("\(label)\(value)")
        if let labelRange = fullText.range(of: label) {
            // Use the labelFont directly (with bold weight)
            fullText[labelRange].font = labelFont
            // Apply label color if provided
            if let labelColor = labelColor {
                fullText[labelRange].foregroundColor = labelColor
            }
        }
        if let valueRange = fullText.range(of: value) {
            fullText[valueRange].font = valueFont
        }
        return fullText
    }
    
    private func startAutoPlay() {
        autoPlayTask?.cancel()
        autoPlayTask = Task<Void, Never> { [reduceMotion] in
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(autoPlayInterval * 1_000_000_000))
                if Task.isCancelled { break }
                await MainActor.run {
                    playGifOnly()
                }
            }
        }
    }
    
}

#Preview {
    HeaderView(dataService: DataService())
        .background(Color("AppGreenLight"))
}

