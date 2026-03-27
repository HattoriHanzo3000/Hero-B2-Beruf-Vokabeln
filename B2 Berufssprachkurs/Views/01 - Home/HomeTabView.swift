//
//  HomeTabView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

// MARK: - Home stack row press style
/// Subtle scale and opacity on press, similar to system list rows and tappable cards.
private struct HomeStackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Home Tab View
struct HomeTabView: View {
    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    private let isPremiumPreviewOverride: Bool?
    @State private var activeStack: LearningStackType?
    @State private var showPaywall = false

    init(isPremiumPreviewOverride: Bool? = nil) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
    }
    
    var body: some View {
        ZStack {
            Color("AppGreenExtraLight")
                .ignoresSafeArea()
            
            // Playful word background
            WordWallpaperBackground(dataService: dataService)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                HeaderView(
                    dataService: dataService,
                    isPremiumPreviewOverride: isPremiumPreviewOverride
                )
                    .id("header_\(languageManager.currentLanguage)")
                
                // Vertical stack of learning rows (full-width, layered stack styling)
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack {
                            Spacer(minLength: 0)
                            VStack(spacing: 28) {
                                Button {
                                    HapticManager.shared.lightImpact()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        activeStack = .general
                                    }
                                } label: {
                                    LearningStackCard(
                                        title: Localizable.string(Localizable.generalWords),
                                        accent: Color("AppGreen"),
                                        icon: "square.stack.3d.up.fill"
                                    )
                                    .frame(maxWidth: .infinity, minHeight: 76)
                                }
                                .buttonStyle(HomeStackButtonStyle())
                                .id("general_\(languageManager.currentLanguage)")

                                Button {
                                    HapticManager.shared.lightImpact()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        activeStack = .verbs
                                    }
                                } label: {
                                    LearningStackCard(
                                        title: Localizable.string(Localizable.verbsWithPrepositions),
                                        accent: Color("AppBlue"),
                                        icon: "figure.run"
                                    )
                                    .frame(maxWidth: .infinity, minHeight: 76)
                                }
                                .buttonStyle(HomeStackButtonStyle())
                                .id("verbs_\(languageManager.currentLanguage)")

                                Button {
                                    HapticManager.shared.lightImpact()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        activeStack = .adjectives
                                    }
                                } label: {
                                    LearningStackCard(
                                        title: Localizable.string(Localizable.adjectivesWithPrepositions),
                                        accent: Color("AppPurple"),
                                        icon: "paintbrush.fill"
                                    )
                                    .frame(maxWidth: .infinity, minHeight: 76)
                                }
                                .buttonStyle(HomeStackButtonStyle())
                                .id("adjectives_\(languageManager.currentLanguage)")

                                Button {
                                    if effectivePremiumActive {
                                        HapticManager.shared.lightImpact()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            activeStack = .favorites
                                        }
                                    } else {
                                        HapticManager.shared.heavyImpact()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            showPaywall = true
                                        }
                                    }
                                } label: {
                                    LearningStackCard(
                                        title: Localizable.string(Localizable.favoritesWordsTitle),
                                        accent: Color("AppYellow"),
                                        icon: "star.fill",
                                        isLocked: false
                                    )
                                    .frame(maxWidth: .infinity, minHeight: 76)
                                }
                                .buttonStyle(HomeStackButtonStyle())
                                .id("favorites_\(languageManager.currentLanguage)")
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            Spacer(minLength: 0)
                        }
                        .padding(.bottom, 32)
                        .frame(minHeight: geometry.size.height)
                    }
                }
                
            }
        }
        .fullScreenCover(item: $activeStack) { stack in
            switch stack {
            case .general:
                GeneralWordsView()
                    .environmentObject(dataService)
            case .verbs:
                VerbsView()
                    .environmentObject(dataService)
            case .adjectives:
                AdjectivesView()
                    .environmentObject(dataService)
            case .favorites:
                FavoritesView()
                    .environmentObject(dataService)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var effectivePremiumActive: Bool {
        isPremiumPreviewOverride ?? subscriptionManager.isPremiumActive
    }
}

// MARK: - Learning Stack Type
enum LearningStackType: Identifiable {
    case general
    case verbs
    case adjectives
    case favorites
    
    var id: String {
        switch self {
        case .general: return "general"
        case .verbs: return "verbs"
        case .adjectives: return "adjectives"
        case .favorites: return "favorites"
        }
    }
}

// MARK: - Learning Stack Card
struct LearningStackCard: View {
    let title: String
    let accent: Color
    let icon: String
    var isLocked: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Localized titles sometimes use `\n` (e.g. favorites); a single-line cap would hide the rest and show "…".
    private var displayTitle: String {
        title
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
    }

    /// Up to 2 lines for default–XXXLarge (long phrases + space instead of newline); more at accessibility sizes.
    private var titleLineRange: ClosedRange<Int> {
        dynamicTypeSize < .accessibility1 ? 1...2 : 1...4
    }

    private var titleMinimumScale: CGFloat {
        dynamicTypeSize < .accessibility1 ? 0.8 : 1.0
    }

    var body: some View {
        ZStack {
            // Bottom layer (stack effect) - NOW SOLID ACCENT COLOR
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(accent)
                .offset(x: 0, y: 14)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 7)
            
            // Middle layer - LIKE TOP LAYER BUT WITH DOUBLED OPACITY
            ZStack {
                if colorScheme == .dark {
                    // Dark mode: black base with accent at doubled opacity (0.8)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(accent.opacity(0.8))
                } else {
                    // Light mode: white base with accent at doubled opacity (0.5)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(accent.opacity(0.5))
                }
            }
            .offset(x: 0, y: 8)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 5)
            
            // Top card - light accent color background with transparency
            ZStack {
                // Background layer
                if colorScheme == .dark {
                    // Dark mode: use darker version of accent color
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(accent.opacity(0.4))
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(accent.opacity(0.25))
                }
                
                // Content layer — icon leading, title trailing (row button)
                HStack(alignment: .center, spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accent)
                            .frame(width: 48, height: 48)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                    }

                    HStack(alignment: .center, spacing: 8) {
                        Text(displayTitle)
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundColor(accent)
                            .multilineTextAlignment(.leading)
                            .lineLimit(titleLineRange)
                            .minimumScaleFactor(titleMinimumScale)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(accent)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Word Wallpaper Background
struct WordWallpaperBackground: View {
    @ObservedObject var dataService: DataService
    @State private var words: [String] = []
    
    private let fontSize: CGFloat = 18
    private let lineSpacing: CGFloat = 24
    
    var body: some View {
        GeometryReader { geometry in
            // Calculate size needed to cover screen when rotated 45 degrees
            // Diagonal of screen = sqrt(width^2 + height^2)
            // To cover all corners, we need at least 2x the diagonal
            let screenDiagonal = sqrt(geometry.size.width * geometry.size.width + geometry.size.height * geometry.size.height)
            let contentWidth = screenDiagonal * 3.0
            let contentHeight = screenDiagonal * 3.0
            
            // Create text like a book page - words flow in lines
            Text(words.joined(separator: " "))
                .font(.system(size: fontSize, design: .rounded))
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
        
        // Collect all German words from all sections
        for (_, wordList) in dataService.wordsBySection {
            for word in wordList {
                if !word.german.isEmpty {
                    allWords.append(word.german)
                }
            }
        }
        
        // Shuffle and take enough words to fill the background
        let shuffled = allWords.shuffled()
        // Use all available words, repeating if needed to ensure full coverage
        if shuffled.count >= 800 {
            words = Array(shuffled.prefix(800))
        } else {
            // Repeat words if we don't have enough
            var repeatedWords: [String] = []
            while repeatedWords.count < 800 {
                repeatedWords.append(contentsOf: shuffled)
            }
            words = Array(repeatedWords.prefix(800))
        }
    }
}

/// Ensures canvas previews use German strings (matches `LanguageManager` “Deutsch” option).
private struct HomeTabPreviewHost: View {
    let isPremiumPreviewOverride: Bool?

    init(isPremiumPreviewOverride: Bool?) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        LanguageManager.shared.currentLanguage = "Deutsch"
    }

    var body: some View {
        HomeTabView(isPremiumPreviewOverride: isPremiumPreviewOverride)
            .environmentObject(DataService())
    }
}

#Preview("Home Tab - Free") {
    HomeTabPreviewHost(isPremiumPreviewOverride: false)
}

#Preview("Home Tab - Premium") {
    HomeTabPreviewHost(isPremiumPreviewOverride: true)
}

