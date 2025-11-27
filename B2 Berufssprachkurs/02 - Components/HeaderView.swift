//
//  HeaderView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct HeaderView: View {
    @ObservedObject var dataService: DataService
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
        HStack(alignment: .top, spacing: 5) {
            // Mascot on the left top with animation
            mascotView
                .padding(.top, 4)
            
            // 5 rows of text content
            VStack(alignment: .leading, spacing: 8) {
                // Row 1: "Word of the Day" label
                Text(Localizable.string(Localizable.wordOfTheDay))
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundColor(.white.opacity(0.8))
                
                // Row 2: Word of the day
                if let word = wordOfTheDay {
                    Text(word.german)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Row 3: Explanation
                    if let explanation = word.explanation, !explanation.isEmpty {
                        HStack(alignment: .top, spacing: 4) {
                            Text("erkl.:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(explanation)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                    }
                    
                    // Row 4: Synonym
                    if let synonyms = word.synonyms, let firstSynonym = synonyms.first {
                        HStack(spacing: 4) {
                            Text("syn.:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(firstSynonym)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Row 5: Translation
                    if !word.translation.isEmpty && word.translation.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                        HStack(spacing: 4) {
                            Text("übers.:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(word.translation)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                } else {
                    // Empty state
                    Text(Localizable.string(Localizable.wordOfTheDay))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            // Solid gradient background
            LinearGradient(
                colors: [
                    Color("AppGreen").opacity(0.9),
                    Color("AppGreen").opacity(0.65),
                    Color("AppBlue").opacity(0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.3),
                        .white.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        )
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
        .padding(.top, 8)
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

