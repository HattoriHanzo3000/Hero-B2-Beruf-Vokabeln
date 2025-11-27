//
//  CockpitView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct CockpitView: View {
    @StateObject private var dataService = DataService()
    @State private var navigateToSettings = false
    @AppStorage("wordOfTheDaySelectedSections") private var wordOfTheDaySelectedSections = ""
    @AppStorage("wordOfTheDayPeriodicity") private var wordOfTheDayPeriodicity = "24_hours"
    
    var body: some View {
        ZStack {
            Color("AppGreenLight")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: Word of the Day - Friendly Card
                    CockpitCard(
                        titleIcon: "sparkles",
                        title: Localizable.string(Localizable.wordOfTheDay),
                        subtitle: Text(Localizable.string(Localizable.wordOfTheDay))
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            // Friendly intro
                            Text(Localizable.string(Localizable.cockpitWotdIntro))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Customize Word of the Day preferences")
                            
                            // Periodicity control
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.fill")
                                        .font(.footnote)
                                        .foregroundColor(Color("AppGreen"))
                                    Text(Localizable.string(Localizable.periodicity))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Picker("", selection: $wordOfTheDayPeriodicity) {
                                    Text("12h").tag("12_hours")
                                    Text("24h").tag("24_hours")
                                }
                                .pickerStyle(.segmented)
                                .tint(Color("AppGreen"))
                                .accessibilityLabel(Localizable.string(Localizable.periodicity))
                                .onChange(of: wordOfTheDayPeriodicity) { _, _ in
                                    HapticManager.shared.lightImpact()
                                }
                            }
                            
                            // Source sections button
                            NavigationLink {
                                SectionSelectionView(
                                    selectedSections: $wordOfTheDaySelectedSections,
                                    dataService: dataService
                                )
                            } label: {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(Localizable.string(Localizable.sourceSections))
                                        Text(getSelectedSectionsCount() == 0
                                             ? Localizable.string(Localizable.allSections)
                                             : String(format: Localizable.string(Localizable.selectedSections), getSelectedSectionsCount()))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color("AppGreen").opacity(0.12))
                                )
                                .contentShape(Capsule(style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Localizable.string(Localizable.sourceSections))
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal)
                    
                    // MARK: Progress - Under Construction
                    CockpitCard(
                        titleIcon: "chart.line.uptrend.xyaxis",
                        title: Localizable.string(Localizable.progress),
                        subtitle: Text(Localizable.string(Localizable.progressSubtitle))
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            // Under construction message
                            HStack(spacing: 12) {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(Color("AppGreen"))
                                    .frame(width: 34, height: 34)
                                    .background(Color("AppGreen").opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(Localizable.string(Localizable.progressUnderConstruction))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                    Text(Localizable.string(Localizable.progressComingSoon))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal)
                    
                    // Add more content sections here as needed
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    navigateToSettings = true
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.primary)
                }
            }
        }
        .fullScreenCover(isPresented: $navigateToSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(dataService)
            }
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
    @ViewBuilder let content: Content
    
    init(titleIcon: String, title: String, subtitle: Text? = nil, @ViewBuilder content: () -> Content) {
        self.titleIcon = titleIcon
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: titleIcon)
                    .font(.headline.weight(.semibold))
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
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }
            
            content
        }
        .padding(16)
        .background(
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
                .font(.body)
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
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(title)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
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
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color("AppGreen"))
                )
            
            Text(Localizable.string(Localizable.periodicity))
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

#Preview {
    NavigationStack {
        CockpitView()
    }
}

