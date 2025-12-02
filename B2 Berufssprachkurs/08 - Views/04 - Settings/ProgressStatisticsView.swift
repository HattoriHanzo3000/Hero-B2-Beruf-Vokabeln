//
//  ProgressStatisticsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct ProgressStatisticsView: View {
    @ObservedObject var dataService: DataService
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var refreshID = UUID()
    @State private var progress: (wrong: Int, familiar: Int, reinforced: Int, mastered: Int, total: Int) = (0, 0, 0, 0, 0)
    @State private var readinessPercentage: Int = 0
    
    private func updateStatistics() {
        let allWordIds = dataService.getAllWordIds()
        progress = SpacedRepetitionService.shared.getProgressByLevel(allWordIds: allWordIds)
        readinessPercentage = SpacedRepetitionService.shared.getReadinessPercentage(allWordIds: allWordIds)
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
    
    private var rings: [(value: Double, color: Color, title: String, maxValue: Int)] {
        let total = Double(max(progress.total, 1)) // Ensure at least 1 to avoid division by zero
        
        // Background ring - gray in light mode, black in dark mode
        let backgroundRingColor = colorScheme == .dark ? Color.black : Color(.systemGray4)
        let backgroundRing = (1.0, backgroundRingColor, "", 0)
        
        // Data rings - sorted by count (descending) so smaller counts appear on top
        let dataRings = [
            (Double(progress.mastered) / total, Color("AppGreen"), Localizable.string(Localizable.statisticsMasteredTitle), progress.mastered),
            (Double(progress.reinforced) / total, Color("AppBlue"), Localizable.string(Localizable.statisticsReinforcedTitle), progress.reinforced),
            (Double(progress.familiar) / total, Color.yellow, Localizable.string(Localizable.statisticsFamiliarTitle), progress.familiar),
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
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 260, height: 260)
                .contentShape(Rectangle())
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isPulsing)
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
            // Row 1: Wrong (Red), Familiar (Orange)
            StatisticsGridCard(
                title: Localizable.string(Localizable.statisticsWrongTitle),
                count: progress.wrong,
                description: Localizable.string(Localizable.statisticsWrongDescription),
                color: Color("AppRed")
            )
            .id("wrong_\(languageManager.currentLanguage)")
            
            StatisticsGridCard(
                title: Localizable.string(Localizable.statisticsFamiliarTitle),
                count: progress.familiar,
                description: Localizable.string(Localizable.statisticsFamiliarDescription),
                color: .yellow
            )
            .id("familiar_\(languageManager.currentLanguage)")
            
            // Row 2: Reinforced (Blue), Mastered (Green)
            StatisticsGridCard(
                title: Localizable.string(Localizable.statisticsReinforcedTitle),
                count: progress.reinforced,
                description: Localizable.string(Localizable.statisticsReinforcedDescription),
                color: Color("AppBlue")
            )
            .id("reinforced_\(languageManager.currentLanguage)")
            
            StatisticsGridCard(
                title: Localizable.string(Localizable.statisticsMasteredTitle),
                count: progress.mastered,
                description: Localizable.string(Localizable.statisticsMasteredDescription),
                color: Color("AppGreen")
            )
            .id("mastered_\(languageManager.currentLanguage)")
        }
    }
}

struct StatisticsGridCard: View {
    let title: String
    let count: Int
    let description: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    // Inverted text color: always white
    private var invertedTextColor: Color {
        .white
    }
    
    // Inverted secondary text color: always white with slight transparency
    private var invertedSecondaryTextColor: Color {
        .white.opacity(0.9)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: Title (left) and Count (right)
            HStack {
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundColor(invertedTextColor)
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundColor(invertedTextColor)
            }
            
            // Description text below - reserved for 2 rows, expands with accessibility
            Text(description)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(invertedSecondaryTextColor)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(minHeight: 100)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color)
        )
    }
}

