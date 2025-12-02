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
    @State private var showPremiumAlert = false
    
    var body: some View {
        ZStack {
            Color("AppGreenExtraLight")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                HeaderView(dataService: dataService)
                    .id("header_\(languageManager.currentLanguage)")
                
                // Scrollable block of learning stacks
                ScrollView {
                    VStack(spacing: 16) {
                        LearningStackCard(
                            title: Localizable.string(Localizable.generalWords),
                            accent: Color("AppGreen"),
                            icon: "square.stack.3d.up.fill"
                        )
                        .id("general_\(languageManager.currentLanguage)")
                        .onTapGesture {
                            HapticManager.shared.lightImpact()
                            activeStack = .general
                        }
                        
                        LearningStackCard(
                            title: Localizable.string(Localizable.verbsWithPrepositions),
                            accent: Color("AppBlue"),
                            icon: "square.stack.3d.up.fill"
                        )
                        .id("verbs_\(languageManager.currentLanguage)")
                        .onTapGesture {
                            HapticManager.shared.lightImpact()
                            activeStack = .verbs
                        }
                        
                        LearningStackCard(
                            title: Localizable.string(Localizable.adjectivesWithPrepositions),
                            accent: Color.purple,
                            icon: "square.stack.3d.up.fill"
                        )
                        .id("adjectives_\(languageManager.currentLanguage)")
                        .onTapGesture {
                            HapticManager.shared.lightImpact()
                            activeStack = .adjectives
                        }
                        
                        LearningStackCard(
                            title: Localizable.string(Localizable.favorites),
                            accent: Color.yellow,
                            icon: "star.fill",
                            isLocked: !subscriptionManager.isPremiumActive
                        )
                        .id("favorites_\(languageManager.currentLanguage)")
                        .onTapGesture {
                            if subscriptionManager.isPremiumActive {
                                HapticManager.shared.lightImpact()
                                activeStack = .favorites
                            } else {
                                HapticManager.shared.heavyImpact()
                                showPremiumAlert = true
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
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
        .alert(Localizable.string(Localizable.premiumRequired), isPresented: $showPremiumAlert) {
            Button(Localizable.string(Localizable.ok), role: .cancel) { }
        } message: {
            Text(Localizable.string(Localizable.unlockPremiumToUseFeature))
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
    
    var body: some View {
        ZStack {
            // Bottom layer (stack effect)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(accent.opacity(0.15))
                .offset(x: 0, y: 14)
                .shadow(color: accent.opacity(0.2), radius: 10, x: 0, y: 7)
            
            // Middle layer
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(accent.opacity(0.2))
                .offset(x: 0, y: 8)
                .shadow(color: accent.opacity(0.15), radius: 8, x: 0, y: 5)
            
            // Top card - light accent color background with transparency
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent)
                        .frame(width: 52, height: 52)
                        .shadow(color: accent.opacity(0.3), radius: 4, x: 0, y: 2)
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isLocked ? accent : .secondary)
            }
            .padding(22)
            .frame(minHeight: 120, alignment: .center)
            .background(
                // Solid background - no transparency
                Color(.systemBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(accent.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    HomeTabView()
        .environmentObject(DataService())
}

