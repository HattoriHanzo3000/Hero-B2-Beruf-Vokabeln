//
//  CockpitView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct CockpitView: View {
    @StateObject private var dataService = DataService()
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("wordOfTheDaySelectedSections") private var wordOfTheDaySelectedSections = ""
    @AppStorage("wordOfTheDayPeriodicity") private var wordOfTheDayPeriodicity = "24_hours"
    
    // Inverted text color: white in light mode, black in dark mode (matching statistics cards)
    private var invertedTextColor: Color {
        colorScheme == .light ? .white : .black
    }
    
    // Inverted secondary text color: slightly transparent white/black
    private var invertedSecondaryTextColor: Color {
        colorScheme == .light ? .white.opacity(0.9) : .black.opacity(0.8)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color("AppGreenExtraLight")
                .ignoresSafeArea()
            
            // Playful word background
            WordWallpaperBackground(dataService: dataService)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: Pro promo section — only in Basis mode
                    if !subscriptionManager.isPremiumActive {
                        ProPromoSection(
                            isPremiumActive: subscriptionManager.isPremiumActive,
                            hasUsedTrial: subscriptionManager.hasUsedTrial,
                            hasActiveSubscription: subscriptionManager.hasActiveSubscription,
                            onStartFreeTrial: {
                                HapticManager.shared.mediumImpact()
                                showPaywall = true
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // MARK: Word of the Day - Friendly Card
                    CockpitCard(
                        titleIcon: subscriptionManager.isPremiumActive ? "calendar" : "crown.fill",
                        title: Localizable.string(Localizable.wordOfTheDay),
                        subtitle: Text(Localizable.string(Localizable.wordOfTheDayDescription))
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            
                            // Periodicity control
                            HStack(spacing: 10) {
                                Image(systemName: "clock.fill")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(Localizable.string(Localizable.periodicity))
                                    .font(.system(.body, design: .rounded).weight(.bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Circular buttons
                                HStack(spacing: 8) {
                                    Button {
                                        if subscriptionManager.isPremiumActive {
                                            HapticManager.shared.lightImpact()
                                            wordOfTheDayPeriodicity = "12_hours"
                                        } else {
                                            HapticManager.shared.heavyImpact()
                                            showPaywall = true
                                        }
                                    } label: {
                                        Text(Localizable.string(Localizable.hours12Short))
                                            .font(.system(.body, design: .rounded).weight(.bold))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(wordOfTheDayPeriodicity == "12_hours" ? (colorScheme == .light ? Color.white.opacity(0.6) : Color.black.opacity(0.5)) : (colorScheme == .light ? Color.white.opacity(0.15) : Color.black.opacity(0.1)))
                                            )
                                    }
                                    .id("12h_\(languageManager.currentLanguage)")
                                    
                                    Button {
                                        if subscriptionManager.isPremiumActive {
                                            HapticManager.shared.lightImpact()
                                            wordOfTheDayPeriodicity = "24_hours"
                                        } else {
                                            HapticManager.shared.heavyImpact()
                                            showPaywall = true
                                        }
                                    } label: {
                                        Text(Localizable.string(Localizable.hours24Short))
                                            .font(.system(.body, design: .rounded).weight(.bold))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(wordOfTheDayPeriodicity == "24_hours" ? (colorScheme == .light ? Color.white.opacity(0.6) : Color.black.opacity(0.5)) : (colorScheme == .light ? Color.white.opacity(0.15) : Color.black.opacity(0.1)))
                                            )
                                    }
                                    .id("24h_\(languageManager.currentLanguage)")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("AppGreen"),
                                                Color("AppBlue")
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .contentShape(Capsule(style: .continuous))
                            
                            // Source sections button - accessible to all users
                            NavigationLink {
                                SectionSelectionView(
                                    selectedSections: $wordOfTheDaySelectedSections,
                                    dataService: dataService
                                )
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "checklist")
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(Localizable.string(Localizable.sourceSections))
                                            .font(.system(.body, design: .rounded).weight(.bold))
                                            .foregroundColor(.white)
                                        Text(getSelectedSectionsCount() == 0
                                             ? Localizable.string(Localizable.allSections)
                                             : String(format: Localizable.string(Localizable.selectedSections), getSelectedSectionsCount()))
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(.caption, design: .rounded).weight(.semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color("AppGreen"),
                                                    Color("AppBlue")
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .contentShape(Capsule(style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Localizable.string(Localizable.sourceSections))
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal)
                    
                    // MARK: Progress - Statistics Wheel
                    CockpitCard(
                        titleIcon: subscriptionManager.isPremiumActive ? "chart.line.uptrend.xyaxis" : "crown.fill",
                        title: Localizable.string(Localizable.progress),
                        subtitle: Text(String(format: Localizable.string(Localizable.progressDescription), dataService.getAllWordIds().count))
                    ) {
                        ProgressStatisticsView(dataService: dataService, isPremiumActive: subscriptionManager.isPremiumActive)
                            .padding(.top, 2)
                    }
                    .padding(.horizontal)
                    
                    // Add more content sections here as needed
                }
                .padding(.vertical)
                .padding(.bottom, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            // Initialize to 1A if empty (first time use)
            if wordOfTheDaySelectedSections.isEmpty {
                wordOfTheDaySelectedSections = "1A"
            }
        }
        .environmentObject(dataService)
    }
    
    private func getSelectedSectionsCount() -> Int {
        if wordOfTheDaySelectedSections.isEmpty {
            return 1 // Default is 1A
        }
        return wordOfTheDaySelectedSections.split(separator: ",").count
    }
}

// MARK: - Cockpit Card
private struct CockpitCard<Content: View>: View {
    let titleIcon: String
    let title: String
    let subtitle: Text?
    let useGlassEffect: Bool
    @ViewBuilder let content: Content
    
    init(titleIcon: String, title: String, subtitle: Text? = nil, useGlassEffect: Bool = true, @ViewBuilder content: () -> Content) {
        self.titleIcon = titleIcon
        self.title = title
        self.subtitle = subtitle
        self.useGlassEffect = useGlassEffect
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: titleIcon)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        LinearGradient(
                            colors: [Color("AppGreen"), Color("AppBlue").opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }
            
            // Subtitle description
            if let subtitle = subtitle {
                subtitle
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            content
        }
        .padding(16)
        .background(
            Group {
                if useGlassEffect {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    Color.white.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color("AppGreenExtraLight"))
                        )
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color("AppGreenExtraLight"))
                }
            }
        )
        .overlay(
            Group {
                if useGlassEffect {
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
                }
            }
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Cockpit Row View
private struct CockpitRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(iconColor)
                )
            
            if let subtitle = subtitle {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
            } else {
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color("AppGreenExtraLight"))
        .cornerRadius(12)
    }
}

// MARK: - Cockpit Periodicity Row View
private struct CockpitPeriodicityRowView: View {
    @Binding var periodicity: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color("AppGreen"))
                )
            
            Text(Localizable.string(Localizable.periodicity))
                .font(.system(.body, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer()
            
            // iOS 26 System Segmented Control
            Picker("", selection: $periodicity) {
                Text("12h")
                    .tag("12_hours")
                Text("24h")
                    .tag("24_hours")
            }
            .pickerStyle(.segmented)
            .tint(Color("AppGreen"))
            .frame(width: 120)
            .onChange(of: periodicity) { _, _ in
                HapticManager.shared.lightImpact()
            }
        }
        .padding()
        .background(Color("AppGreenExtraLight"))
        .cornerRadius(12)
    }
}

// MARK: - Pro promo section
private struct ProPromoSection: View {
    let isPremiumActive: Bool
    let hasUsedTrial: Bool
    let hasActiveSubscription: Bool
    let onStartFreeTrial: () -> Void
    
    // Determine if user was previously subscribed but is now unsubscribed
    private var wasSubscribed: Bool {
        // User was subscribed if they used trial (which means they either used trial or subscribed) but now don't have premium
        return hasUsedTrial && !isPremiumActive
    }
    
    private var title: String {
        if isPremiumActive {
            return Localizable.string(Localizable.enjoyHeroPremium)
        } else if wasSubscribed {
            return Localizable.string(Localizable.getPremiumFeaturesBack)
        } else {
            return Localizable.string(Localizable.unlockHeroPremium)
        }
    }
    
    private var subtitle: String {
        if isPremiumActive {
            return Localizable.string(Localizable.premiumActiveSubtitle)
        } else if wasSubscribed {
            return Localizable.string(Localizable.premiumFeaturesBackSubtitle)
        } else {
            return Localizable.string(Localizable.premiumPromoSubtitle)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                // Crown icon - white
                Image(systemName: "crown.fill")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title - changes based on premium status
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                    
                    // Subtitle - changes based on premium status
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            
            // Button - only show when premium is not active
            if !isPremiumActive {
                Button(action: onStartFreeTrial) {
                    Text(hasUsedTrial ? Localizable.string(Localizable.upgradeToPremium) : Localizable.string(Localizable.startFreeTrial))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                        )
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color("AppGreen"),
                            Color("AppBlue")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

#Preview {
    NavigationStack {
        CockpitView()
    }
}
