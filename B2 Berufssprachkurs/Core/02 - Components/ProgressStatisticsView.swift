//
//  ProgressStatisticsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct ProgressStatisticsView: View {
    @ObservedObject var dataService: DataService
    let isPremiumActive: Bool
    /// When set, shows the same distribution/readiness as the matching debug preset without touching saved study data (e.g. canvas previews).
    var statisticsPreviewPreset: SpacedRepetitionService.DebugProgressPreset? = nil
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var refreshID = UUID()
    @State private var progress: (wrong: Int, familiar: Int, reinforced: Int, mastered: Int, total: Int) = (0, 0, 0, 0, 0)
    @State private var readinessPercentage: Int = 0
    
    private func updateStatistics() {
        if isPremiumActive {
            let allWordIds = dataService.getAllWordIds()
            if let preset = statisticsPreviewPreset {
                let stats = SpacedRepetitionService.shared.previewStatistics(for: preset, allWordIds: allWordIds)
                progress = (stats.wrong, stats.familiar, stats.reinforced, stats.mastered, stats.total)
                readinessPercentage = stats.readinessPercentage
            } else {
                progress = SpacedRepetitionService.shared.getProgressByLevel(allWordIds: allWordIds)
                readinessPercentage = SpacedRepetitionService.shared.getReadinessPercentage(allWordIds: allWordIds)
            }
        } else {
            // In basis mode, everything stays 0
            progress = (0, 0, 0, 0, 0)
            readinessPercentage = 0
        }
        refreshID = UUID()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Circular chart
            RingChartView(progress: progress, readinessPercentage: readinessPercentage)
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .id(refreshID)
            
            // Statistics grid (2x2)
            StatisticsGridView(progress: progress)
                .id("\(refreshID)_\(languageManager.currentLanguage)")
        }
        .onAppear {
            updateStatistics()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SpacedRepetitionUpdated"))) { _ in
            updateStatistics()
        }
        .onChange(of: languageManager.currentLanguage) { _, _ in
            refreshID = UUID()
        }
    }
}

struct RingChartView: View {
    let progress: (wrong: Int, familiar: Int, reinforced: Int, mastered: Int, total: Int)
    let readinessPercentage: Int
    @State private var isPulsing: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private static let readinessPulseDuration: Double = 1.45
    
    private var rings: [(value: Double, color: Color, title: String, maxValue: Int)] {
        let total = Double(max(progress.total, 1)) // Ensure at least 1 to avoid division by zero
        
        // Background ring - gray in light mode, black in dark mode
        let backgroundRingColor = colorScheme == .dark ? Color.black : Color(.systemGray4)
        let backgroundRing = (1.0, backgroundRingColor, "", 0)
        
        // Data rings - sorted by count (descending) so smaller counts appear on top
        let dataRings = [
            (Double(progress.mastered) / total, Color("AppGreen"), Localizable.string(Localizable.statisticsMasteredTitle), progress.mastered),
            (Double(progress.reinforced) / total, Color("AppBlue"), Localizable.string(Localizable.statisticsReinforcedTitle), progress.reinforced),
            (Double(progress.familiar) / total, Color("AppYellow"), Localizable.string(Localizable.statisticsFamiliarTitle), progress.familiar),
            (Double(progress.wrong) / total, Color("AppRed"), Localizable.string(Localizable.statisticsWrongTitle), progress.wrong)
        ]
        
        // Sort data rings by count (maxValue) in descending order
        let sortedDataRings = dataRings.sorted { $0.3 > $1.3 }
        
        return [backgroundRing] + sortedDataRings
    }
    
    var body: some View {
        ZStack {
            // Chart rings
            ForEach(Array(rings.enumerated()), id: \.offset) { index, ring in
                RingView(
                    progress: ring.value,
                    color: ring.color,
                    ringIndex: index,
                    totalRings: rings.count
                )
            }
            
            // Center text - explicitly centered
            Text("\(readinessPercentage)%")
                .font(AppFont.fixedExpanded(size: 24, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 260, height: 260)
                .contentShape(Rectangle())
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: Self.readinessPulseDuration).repeatForever(autoreverses: true),
                    value: isPulsing
                )
                .onAppear {
                    // Delay animation slightly to ensure layout is complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPulsing = true
                    }
                }
                .onDisappear { isPulsing = false }
        }
        .frame(width: 260, height: 260)
    }
}

struct RingView: View {
    let progress: Double
    let color: Color
    let ringIndex: Int
    let totalRings: Int
    @State private var animatedProgress: Double = 0
    
    private var ringThickness: CGFloat {
        return 70
    }
    
    private var baseRadius: CGFloat {
        return 130
    }
    
    private var currentRadius: CGFloat {
        return baseRadius
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.clear, lineWidth: ringThickness)
                .frame(width: currentRadius * 2, height: currentRadius * 2)
            
            // Ring progress
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(color, style: StrokeStyle(lineWidth: ringThickness, lineCap: .round))
                .frame(width: currentRadius * 2, height: currentRadius * 2)
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            if ringIndex == 0 {
                // Gray background circle - no animation
                animatedProgress = progress
            } else {
                // Colored progress circles - with animation
                animatedProgress = 0
                withAnimation(.easeOut(duration: 1.0).delay(Double(ringIndex - 1) * 0.15)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

struct StatisticsGridView: View {
    let progress: (wrong: Int, familiar: Int, reinforced: Int, mastered: Int, total: Int)
    @ObservedObject private var languageManager = LanguageManager.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            // Row 1: Wrong (Red), Familiar (Yellow)
            StatisticsGridCard(
                title: Localizable.string(Localizable.statisticsWrongTitle),
                count: progress.wrong,
                description: Localizable.string(Localizable.statisticsWrongDescription),
                gradient: LinearGradient(
                    colors: [
                        Color("AppRed"),
                        Color("AppRed").opacity(0.85),
                        Color("AppRed").opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .id("wrong_\(languageManager.currentLanguage)")
            
            StatisticsGridCard(
                title: Localizable.string(Localizable.statisticsFamiliarTitle),
                count: progress.familiar,
                description: Localizable.string(Localizable.statisticsFamiliarDescription),
                gradient: LinearGradient(
                    colors: [
                        Color("AppYellow"),
                        Color("AppYellow").opacity(0.9),
                        Color("AppYellow").opacity(0.75)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .id("familiar_\(languageManager.currentLanguage)")
            
            // Row 2: Reinforced (Blue), Mastered (Green)
            StatisticsGridCard(
                title: Localizable.string(Localizable.statisticsReinforcedTitle),
                count: progress.reinforced,
                description: Localizable.string(Localizable.statisticsReinforcedDescription),
                gradient: LinearGradient(
                    colors: [
                        Color("AppBlue"),
                        Color("AppBlue").opacity(0.9),
                        Color("AppBlue").opacity(0.75)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .id("reinforced_\(languageManager.currentLanguage)")
            
            StatisticsGridCard(
                title: Localizable.string(Localizable.statisticsMasteredTitle),
                count: progress.mastered,
                description: Localizable.string(Localizable.statisticsMasteredDescription),
                gradient: LinearGradient(
                    colors: [
                        Color("AppGreen"),
                        Color("AppGreen").opacity(0.9),
                        Color("AppGreen").opacity(0.75)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .id("mastered_\(languageManager.currentLanguage)")
        }
    }
}

struct StatisticsGridCard: View {
    let title: String
    let count: Int
    let description: String
    let gradient: LinearGradient

    @State private var isFlipped = false
    @State private var flipBackTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let titlePointSize: CGFloat = 17
    private static let countPointSize: CGFloat = 18
    private static let descriptionPointSize: CGFloat = 15
    private static let flipBackDelaySeconds: TimeInterval = 10

    private var invertedTextColor: Color { .white }
    /// One step lighter than full white on gradient cards (titles / counts).
    private var invertedTitleColor: Color { .white.opacity(0.92) }
    private var invertedCountColor: Color { .white.opacity(0.94) }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(gradient)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
    }

    var body: some View {
        ZStack {
            frontFace
                .opacity(isFlipped ? 0 : 1)
            backFace
                .rotation3DEffect(reduceMotion ? .degrees(0) : .degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(reduceMotion ? .degrees(0) : .degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .frame(minHeight: 100)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.shared.lightImpact()
            flipCard()
        }
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onDisappear { flipBackTask?.cancel() }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(title), \(count)")
        .accessibilityValue(description)
        .accessibilityHint(Localizable.string(Localizable.statisticsCardFlipHint))
    }

    private func flipCard() {
        flipBackTask?.cancel()
        withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.4, dampingFraction: 0.75)) {
            isFlipped.toggle()
        }
        if isFlipped {
            let delay = Self.flipBackDelaySeconds
            flipBackTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.4, dampingFraction: 0.75)) {
                        isFlipped = false
                    }
                }
            }
        }
    }

    /// Front: category title and count (matches pre-flip layout).
    private var frontFace: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: Self.titlePointSize, weight: .medium, design: .default))
                .foregroundColor(invertedTitleColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(count)")
                .font(AppFont.fixedExpanded(size: Self.countPointSize, weight: .semibold))
                .foregroundColor(invertedCountColor)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(cardBackground)
    }

    /// Back: explanation only (readable after 180° flip).
    private var backFace: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(description)
                .font(.system(size: Self.descriptionPointSize, weight: .regular, design: .default))
                .foregroundColor(invertedTextColor)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .background(cardBackground)
    }
}

