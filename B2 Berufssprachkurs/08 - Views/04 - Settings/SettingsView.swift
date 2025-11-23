//
//  SettingsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: DataService
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("wordOfTheDayEnabled") private var wordOfTheDayEnabled = true
    @AppStorage("wordOfTheDayPeriodicity") private var wordOfTheDayPeriodicity = "24 hours" // "12 hours" or "24 hours"
    @AppStorage("wordOfTheDaySelectedSections") private var wordOfTheDaySelectedSections = "" // Comma-separated section IDs, empty means all
    @State private var showResetAlert = false
    @State private var showSectionSelection = false
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                    .accessibilityHint("Return to previous screen")
                    
                    Spacer()
                    
                    Text("Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                
                // Settings content
                ScrollView {
                    VStack(spacing: 20) {
                        // Section 1: Version
                        settingsSection {
                            SettingsRow(
                                icon: "info.circle.fill",
                                iconColor: .blue,
                                title: "Version",
                                subtitle: "\(appVersion) (\(buildNumber))",
                                action: {
                                    openAppStore()
                                }
                            )
                        }
                        
                        // Section 2: Premium
                        settingsSection {
                            SettingsRow(
                                icon: "crown.fill",
                                iconColor: .yellow,
                                title: "Premium",
                                showChevron: true,
                                action: {
                                    // Handle premium tap
                                }
                            )
                        }
                        
                        // Section 3: Word of the Day
                        settingsSection {
                            SettingsRow(
                                icon: "calendar",
                                iconColor: .orange,
                                title: "Word of the Day",
                                showToggle: true,
                                toggleValue: $wordOfTheDayEnabled
                            )
                            
                            if wordOfTheDayEnabled {
                                Divider()
                                    .padding(.leading, 56)
                                
                                // Periodicity row
                                PeriodicityRow(
                                    periodicity: $wordOfTheDayPeriodicity
                                )
                                
                                Divider()
                                    .padding(.leading, 56)
                                
                                // Source Sections row
                                SourceSectionsRow(
                                    selectedSections: $wordOfTheDaySelectedSections,
                                    dataService: dataService,
                                    onTap: {
                                        showSectionSelection = true
                                    }
                                )
                            }
                        }
                        
                        // Section 4: Preferences
                        settingsSection {
                            SettingsRow(
                                icon: "hand.tap.fill",
                                iconColor: .purple,
                                title: "Haptic Feedback",
                                showToggle: true,
                                toggleValue: $hapticFeedbackEnabled
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingsRow(
                                icon: "paintbrush.fill",
                                iconColor: .pink,
                                title: "Appearance",
                                subtitle: "System",
                                showChevron: true,
                                action: {
                                    // Handle appearance tap
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingsRow(
                                icon: "textformat.size",
                                iconColor: .indigo,
                                title: "Display and Text Size",
                                showChevron: true,
                                action: {
                                    // Handle display settings tap
                                }
                            )
                        }
                        
                        // Section 5: Support
                        settingsSection {
                            SettingsRow(
                                icon: "questionmark.circle.fill",
                                iconColor: .blue,
                                title: "FAQ",
                                showChevron: true,
                                action: {
                                    // Handle FAQ tap
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingsRow(
                                icon: "envelope.fill",
                                iconColor: .blue,
                                title: "Contact Us",
                                showChevron: true,
                                action: {
                                    openContactUs()
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingsRow(
                                icon: "exclamationmark.triangle.fill",
                                iconColor: .orange,
                                title: "Report a Bug",
                                showChevron: true,
                                action: {
                                    openReportBug()
                                }
                            )
                        }
                        
                        // Section 6: Legal
                        settingsSection {
                            SettingsRow(
                                icon: "doc.text.fill",
                                iconColor: .gray,
                                title: "Impressum",
                                showChevron: true,
                                action: {
                                    // Handle impressum tap
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingsRow(
                                icon: "doc.text.fill",
                                iconColor: .gray,
                                title: "Terms of Use",
                                showChevron: true,
                                action: {
                                    // Handle terms tap
                                }
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingsRow(
                                icon: "lock.shield.fill",
                                iconColor: .gray,
                                title: "Privacy Policy",
                                showChevron: true,
                                action: {
                                    // Handle privacy policy tap
                                }
                            )
                        }
                        
                        // Section 7: Reset
                        settingsSection {
                            SettingsRow(
                                icon: "arrow.counterclockwise",
                                iconColor: .red,
                                title: "Reset App",
                                showChevron: true,
                                action: {
                                    showResetAlert = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showSectionSelection) {
            SectionSelectionView(
                selectedSections: $wordOfTheDaySelectedSections,
                dataService: dataService
            )
        }
        .alert("Reset App", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetApp()
            }
        } message: {
            Text("This will reset all your progress and settings. This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    private func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func openAppStore() {
        // Replace with your actual App Store URL
        if let url = URL(string: "https://apps.apple.com/app/id1234567890") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openContactUs() {
        if let url = URL(string: "mailto:support@example.com?subject=B2%20Berufssprachkurs%20Support") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openReportBug() {
        if let url = URL(string: "mailto:support@example.com?subject=Bug%20Report%20-%20B2%20Berufssprachkurs") {
            UIApplication.shared.open(url)
        }
    }
    
    private func resetApp() {
        // Reset all app data
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        
        // You may want to reset DataService here as well
        // dataService.resetAllData()
    }
    
    private func getSelectedSectionsCount() -> Int {
        if wordOfTheDaySelectedSections.isEmpty {
            return 0 // 0 means "all"
        }
        return wordOfTheDaySelectedSections.split(separator: ",").count
    }
}

// Periodicity Row Component
struct PeriodicityRow: View {
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
                        .fill(Color.orange)
                )
            
            Text("Periodicity")
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Menu {
                Button(action: {
                    periodicity = "12 hours"
                }) {
                    HStack {
                        Text("12 hours")
                        if periodicity == "12 hours" {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button(action: {
                    periodicity = "24 hours"
                }) {
                    HStack {
                        Text("24 hours")
                        if periodicity == "24 hours" {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(periodicity)
                        .font(.body)
                        .foregroundColor(.blue)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityLabel("Periodicity")
        .accessibilityValue(periodicity)
        .accessibilityHint("Select how often to show a new word")
    }
}

// Source Sections Row Component
struct SourceSectionsRow: View {
    @Binding var selectedSections: String
    @ObservedObject var dataService: DataService
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            onTap()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.orange)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Source Sections")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    let selectedCount = getSelectedSectionsCount()
                    Text(selectedCount == 0 ? "All sections" : "\(selectedCount) section\(selectedCount == 1 ? "" : "s") selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Source Sections")
        .accessibilityHint("Choose which sections and lections to include")
    }
    
    private func getSelectedSectionsCount() -> Int {
        if selectedSections.isEmpty {
            return 0 // 0 means "all"
        }
        return selectedSections.split(separator: ",").count
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var showToggle: Bool = false
    var showChevron: Bool = false
    var toggleValue: Binding<Bool>? = nil
    var action: (() -> Void)? = nil
    
    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        showToggle: Bool = false,
        showChevron: Bool = false,
        toggleValue: Binding<Bool>? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showToggle = showToggle
        self.showChevron = showChevron
        self.toggleValue = toggleValue
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action?()
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(iconColor)
                    )
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Toggle or Chevron
                if showToggle, let toggleBinding = toggleValue {
                    Toggle("", isOn: toggleBinding)
                        .labelsHidden()
                        .tint(iconColor)
                } else if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle ?? "")
        .accessibilityAddTraits(showToggle ? [] : .isButton)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(DataService())
    }
}
