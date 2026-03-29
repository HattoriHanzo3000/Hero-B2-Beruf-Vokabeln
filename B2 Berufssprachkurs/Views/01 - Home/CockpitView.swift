//
//  CockpitView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import UIKit

/// Cockpit-only WOTD rows: liquid glass (regular material) + App Green tint at 0.9 opacity. Üben controls are separate.
private struct WotdLiquidGlassCapsuleBackground: View {
    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.regularMaterial)
            Capsule(style: .continuous)
                .fill(Color("AppGreen").opacity(0.75))
        }
    }
}

struct CockpitView: View {
    private let isPremiumPreviewOverride: Bool?

    @StateObject private var dataService: DataService
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showPaywall = false
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("wordOfTheDaySelectedSections") private var wordOfTheDaySelectedSections = ""
    @AppStorage("wordOfTheDayPeriodicity") private var wordOfTheDayPeriodicity = "24_hours"

    private static let wotdControlFontSize: CGFloat = 17
    private static let wotdControlChevronSize: CGFloat = 13
    /// Comfortable tap height aligned with typical iOS prominent controls (~50pt row).
    private static let wotdControlMinHeight: CGFloat = 52
    private static let wotdControlHorizontalPadding: CGFloat = 18

    /// Pass `true` / `false` for canvas previews only; `nil` uses live subscription state.
    init(isPremiumPreviewOverride: Bool? = nil) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        _dataService = StateObject(wrappedValue: DataService())
    }

    private var isPremiumForUI: Bool {
        isPremiumPreviewOverride ?? subscriptionManager.isPremiumActive
    }

    private var wordOfTheDayPeriodicityBinding: Binding<String> {
        Binding(
            get: { wordOfTheDayPeriodicity },
            set: { wordOfTheDayPeriodicity = $0 }
        )
    }
    
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
            // Same base + `WordWallpaperBackground` as `HomeView` (system grouped + gray word texture).
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            WordWallpaperBackground(dataService: dataService)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: Pro promo section — only in Basis mode
                    if !isPremiumForUI {
                        ProPromoSection(
                            isPremiumActive: isPremiumForUI,
                            hasUsedTrial: subscriptionManager.hasUsedTrial,
                            onStartFreeTrial: {
                                HapticManager.shared.mediumImpact()
                                showPaywall = true
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // MARK: Word of the Day - Friendly Card
                    CockpitCard(
                        titleIcon: "calendar",
                        title: Localizable.string(Localizable.wordOfTheDay),
                        subtitle: Text(Localizable.string(Localizable.wordOfTheDayDescription))
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            
                            // Periodicity control
                            HStack(spacing: 10) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: CockpitView.wotdControlFontSize, weight: .regular, design: .default))
                                    .foregroundStyle(.white)
                                
                                Text(Localizable.string(Localizable.periodicity))
                                    .font(.system(size: CockpitView.wotdControlFontSize, weight: .medium, design: .default))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Menu {
                                    Button {
                                        wordOfTheDayPeriodicityBinding.wrappedValue = "12_hours"
                                        HapticManager.shared.selection()
                                    } label: {
                                        HStack {
                                            Text(Localizable.string(Localizable.hours12))
                                                .font(AppFont.fixedExpanded(size: CockpitView.wotdControlFontSize))
                                            Spacer()
                                            if wordOfTheDayPeriodicity == "12_hours" {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: CockpitView.wotdControlFontSize, weight: .regular, design: .default))
                                            }
                                        }
                                    }
                                    Button {
                                        wordOfTheDayPeriodicityBinding.wrappedValue = "24_hours"
                                        HapticManager.shared.selection()
                                    } label: {
                                        HStack {
                                            Text(Localizable.string(Localizable.hours24))
                                                .font(AppFont.fixedExpanded(size: CockpitView.wotdControlFontSize))
                                            Spacer()
                                            if wordOfTheDayPeriodicity == "24_hours" {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: CockpitView.wotdControlFontSize, weight: .regular, design: .default))
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(
                                            wordOfTheDayPeriodicity == "12_hours"
                                                ? Localizable.string(Localizable.hours12Short)
                                                : Localizable.string(Localizable.hours24Short)
                                        )
                                        .font(AppFont.fixedExpanded(size: CockpitView.wotdControlFontSize))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: CockpitView.wotdControlChevronSize, weight: .regular, design: .default))
                                            .foregroundStyle(.white)
                                            .accessibilityHidden(true)
                                    }
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                                .menuActionDismissBehavior(.automatic)
                                .id("wotd_periodicity_\(languageManager.currentLanguage)")
                            }
                            .frame(maxWidth: .infinity, minHeight: CockpitView.wotdControlMinHeight, alignment: .center)
                            .padding(.horizontal, CockpitView.wotdControlHorizontalPadding)
                            .background(WotdLiquidGlassCapsuleBackground())
                            .contentShape(Capsule(style: .continuous))
                            .simultaneousGesture(
                                TapGesture().onEnded { _ in
                                    HapticManager.shared.lightImpact()
                                }
                            )
                            
                            // Source sections button - accessible to all users
                            NavigationLink {
                                WordOfTheDayListView(
                                    selectedSections: $wordOfTheDaySelectedSections,
                                    dataService: dataService
                                )
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "checklist")
                                        .font(.system(size: CockpitView.wotdControlFontSize, weight: .regular, design: .default))
                                        .foregroundStyle(.white)
                                    
                                    Text(Localizable.string(Localizable.sourceSections))
                                        .font(.system(size: CockpitView.wotdControlFontSize, weight: .medium, design: .default))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 6) {
                                        Text("\(getSelectedSectionsCount())")
                                            .font(AppFont.fixedExpanded(size: CockpitView.wotdControlFontSize))
                                            .foregroundStyle(.white)
                                            .monospacedDigit()
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.75)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: CockpitView.wotdControlChevronSize, weight: .regular, design: .default))
                                            .foregroundStyle(.white)
                                            .accessibilityHidden(true)
                                    }
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                                .frame(maxWidth: .infinity, minHeight: CockpitView.wotdControlMinHeight, alignment: .center)
                                .padding(.horizontal, CockpitView.wotdControlHorizontalPadding)
                                .background(WotdLiquidGlassCapsuleBackground())
                                .contentShape(Capsule(style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(
                                TapGesture().onEnded { _ in
                                    HapticManager.shared.lightImpact()
                                }
                            )
                            .accessibilityLabel(
                                "\(Localizable.string(Localizable.sourceSections)), \(String(format: Localizable.string(Localizable.selectedSections), getSelectedSectionsCount()))"
                            )
                        }
                        .dynamicTypeSize(.large ... .large)
                        .padding(.top, 2)
                    }
                    .padding(.horizontal)
                    
                    // MARK: Progress - Statistics Wheel
                    CockpitCard(
                        titleIcon: "chart.line.uptrend.xyaxis",
                        title: Localizable.string(Localizable.progress),
                        subtitle: Text(String(format: Localizable.string(Localizable.progressDescription), dataService.getAllWordIds().count))
                    ) {
                        ProgressStatisticsView(
                            dataService: dataService,
                            statisticsPreviewPreset: isPremiumPreviewOverride == true ? .p67 : nil
                        )
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

// MARK: - Cockpit Card (Word of the Day + Progress — 20pt continuous corners, same as promo banner)
private struct CockpitCard<Content: View>: View {
    let titleIcon: String
    let title: String
    let subtitle: Text?
    let useGlassEffect: Bool
    @ViewBuilder let content: Content
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
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
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
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
                    .font(.system(.title3, design: .default, weight: .regular))
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }
            
            // Subtitle description
            if let subtitle = subtitle {
                subtitle
                    .font(AppFont.subheadlineCondensedRegular(dynamicTypeSize: dynamicTypeSize))
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

/// Canvas previews use German strings (matches `LanguageManager` “Deutsch” option).
private struct CockpitViewPreviewHost: View {
    let isPremiumPreviewOverride: Bool?

    init(isPremiumPreviewOverride: Bool?) {
        self.isPremiumPreviewOverride = isPremiumPreviewOverride
        LanguageManager.shared.currentLanguage = "Deutsch"
    }

    var body: some View {
        CockpitView(isPremiumPreviewOverride: isPremiumPreviewOverride)
    }
}

private struct CockpitViewCanvasPreview: View {
    let isPremiumPreviewOverride: Bool?

    var body: some View {
        NavigationStack {
            CockpitViewPreviewHost(isPremiumPreviewOverride: isPremiumPreviewOverride)
        }
    }
}

#Preview("Cockpit — Free") {
    CockpitViewCanvasPreview(isPremiumPreviewOverride: false)
}

#Preview("Cockpit — Pro") {
    CockpitViewCanvasPreview(isPremiumPreviewOverride: true)
}
