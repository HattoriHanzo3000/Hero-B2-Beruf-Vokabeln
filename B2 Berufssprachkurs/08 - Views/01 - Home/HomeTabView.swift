//
//  HomeTabView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

// MARK: - Home Tab View
struct HomeTabView: View {
    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var activeStack: LearningStackType?
    @State private var showPaywall = false
    @State private var tappedCardId: String? = nil
    
    var body: some View {
        ZStack {
            Color("AppGreenExtraLight")
                .ignoresSafeArea()
            
            // Playful word background
            WordWallpaperBackground(dataService: dataService)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                HeaderView(dataService: dataService)
                    .id("header_\(languageManager.currentLanguage)")
                
                // Scrollable block of learning stacks
                GeometryReader { geometry in
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack {
                            Spacer()
                            HStack(alignment: .center, spacing: 16) {
                                LearningStackCard(
                                    title: Localizable.string(Localizable.generalWords).replacingOccurrences(of: " ", with: "\n"),
                                    accent: Color("AppGreen"),
                                    icon: "square.stack.3d.up.fill"
                                )
                                .frame(width: geometry.size.height * 0.4, height: geometry.size.height * 0.4)
                                .id("general_\(languageManager.currentLanguage)")
                                .scaleEffect(tappedCardId == "general" ? 0.95 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: tappedCardId)
                                .onTapGesture {
                                    tappedCardId = "general"
                                    HapticManager.shared.lightImpact()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        activeStack = .general
                                        tappedCardId = nil
                                    }
                                }
                                
                                LearningStackCard(
                                    title: Localizable.string(Localizable.verbsWithPrepositions),
                                    accent: Color("AppBlue"),
                                    icon: "bolt.fill"
                                )
                                .frame(width: geometry.size.height * 0.4, height: geometry.size.height * 0.4)
                                .id("verbs_\(languageManager.currentLanguage)")
                                .scaleEffect(tappedCardId == "verbs" ? 0.95 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: tappedCardId)
                                .onTapGesture {
                                    tappedCardId = "verbs"
                                    HapticManager.shared.lightImpact()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        activeStack = .verbs
                                        tappedCardId = nil
                                    }
                                }
                                
                                LearningStackCard(
                                    title: Localizable.string(Localizable.adjectivesWithPrepositions),
                                    accent: Color("AppPurple"),
                                    icon: "paintbrush.fill"
                                )
                                .frame(width: geometry.size.height * 0.4, height: geometry.size.height * 0.4)
                                .id("adjectives_\(languageManager.currentLanguage)")
                                .scaleEffect(tappedCardId == "adjectives" ? 0.95 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: tappedCardId)
                                .onTapGesture {
                                    tappedCardId = "adjectives"
                                    HapticManager.shared.lightImpact()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        activeStack = .adjectives
                                        tappedCardId = nil
                                    }
                                }
                                
                                LearningStackCard(
                                    title: Localizable.string(Localizable.favoritesWordsTitle),
                                    accent: Color("AppYellow"),
                                    icon: "star.fill",
                                    isLocked: false
                                )
                                .frame(width: geometry.size.height * 0.4, height: geometry.size.height * 0.4)
                                .id("favorites_\(languageManager.currentLanguage)")
                                .scaleEffect(tappedCardId == "favorites" ? 0.95 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: tappedCardId)
                                .onTapGesture {
                                    tappedCardId = "favorites"
                                    if subscriptionManager.isPremiumActive {
                                        HapticManager.shared.lightImpact()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            activeStack = .favorites
                                            tappedCardId = nil
                                        }
                                    } else {
                                        HapticManager.shared.heavyImpact()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            showPaywall = true
                                            tappedCardId = nil
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            Spacer()
                        }
                        .frame(height: geometry.size.height)
                    }
                }
                
                // Banner Ad at the bottom
                BannerAd()
                    .padding(.bottom, 8)
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
                
                // Content layer
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accent)
                            .frame(width: 52, height: 52)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.system(size: 22, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                    }
                    
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(accent)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.7)
                    
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(accent)
                    }
                }
                .padding(22)
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

#Preview {
    HomeTabView()
        .environmentObject(DataService())
}

