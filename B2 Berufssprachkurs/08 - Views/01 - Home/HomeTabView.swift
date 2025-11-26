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
    @State private var activeStack: LearningStackType?
    
    var body: some View {
        ZStack {
            Color("AppGreenExtraLight")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                HeaderView(dataService: dataService)
                
                // Scrollable block of learning stacks
                ScrollView {
                    VStack(spacing: 16) {
                        LearningStackCard(
                            title: Localizable.string(Localizable.generalWords),
                            accent: Color("AppGreen"),
                            icon: "square.stack.3d.up.fill"
                        )
                        .onTapGesture {
                            HapticManager.shared.lightImpact()
                            activeStack = .general
                        }
                        
                        LearningStackCard(
                            title: Localizable.string(Localizable.verbsWithPrepositions),
                            accent: Color("AppBlue"),
                            icon: "square.stack.3d.up.fill"
                        )
                        .onTapGesture {
                            HapticManager.shared.lightImpact()
                            activeStack = .verbs
                        }
                        
                        LearningStackCard(
                            title: Localizable.string(Localizable.adjectivesWithPrepositions),
                            accent: Color.purple,
                            icon: "square.stack.3d.up.fill"
                        )
                        .onTapGesture {
                            HapticManager.shared.lightImpact()
                            activeStack = .adjectives
                        }
                        
                        LearningStackCard(
                            title: Localizable.string(Localizable.favorites),
                            accent: Color.yellow,
                            icon: "star.fill"
                        )
                        .onTapGesture {
                            HapticManager.shared.lightImpact()
                            activeStack = .favorites
                        }
                    }
                    .padding(.horizontal)
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
    
    var body: some View {
        ZStack {
            // Bottom layer (stack effect)
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(accent.opacity(0.08))
                .offset(x: 0, y: 14)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 7)
            
            // Middle layer
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(accent.opacity(0.12))
                .offset(x: 0, y: 8)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 5)
            
            // Top card
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent)
                        .frame(width: 52, height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.25), lineWidth: 0.6)
                        )
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(22)
            .frame(minHeight: 120, alignment: .center)
            .background(
                // Frosted glass effect
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.35),
                                .white.opacity(0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.6
                    )
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    HomeTabView()
        .environmentObject(DataService())
}

