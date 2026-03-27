//
//  SettingsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import SwiftData
import MessageUI

struct SettingsView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var languageManager = LanguageManager.shared
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage(MigrationManager.iCloudSyncEnabledKey) private var iCloudSyncEnabled = true
    @AppStorage("appearancePreference") private var appearancePreference = "System" // Stores key: "Light" | "Dark" | "System"
    @AppStorage("appLanguage") private var appLanguage = "Deutsch" { // Stores key: "English" | "Deutsch"
        didSet {
            languageManager.setLanguage(appLanguage)
        }
    }
    @State private var showMailComposer = false
    @State private var showMailUnavailableAlert = false
    @State private var showResetAlert = false
    @State private var presentingLegalURL: URL? = nil
    @State private var showPaywall = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    // Sync with language manager
    private var languageBinding: Binding<String> {
        Binding(
            get: { self.appLanguage },
            set: { newValue in
                self.appLanguage = newValue
                self.languageManager.setLanguage(newValue)
            }
        )
    }
    
    // App metadata
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        List {
            // Premium Section with Gradient
            PremiumPromoSection(
                isPremiumActive: subscriptionManager.isPremiumActive,
                hasUsedTrial: subscriptionManager.hasUsedTrial,
                hasActiveSubscription: subscriptionManager.hasActiveSubscription,
                onStartFreeTrial: {
                    HapticManager.shared.mediumImpact()
                    showPaywall = true
                }
            )
            
            SwiftUI.Section {
                NavigationIconRow(
                    icon: "info.circle.fill",
                    iconColor: .gray,
                    title: Localizable.string(Localizable.about)
                ) {
                    AboutView()
                }
                
                // Share row
                NavigationIconRow(
                    icon: "square.and.arrow.up",
                    iconColor: .blue,
                    title: Localizable.string(Localizable.share)
                ) {
                    ShareView()
                }
            }
            
            SwiftUI.Section {
                MenuIconRow(
                    icon: "globe",
                    iconColor: .blue,
                    title: Localizable.string(Localizable.appLanguage),
                    options: localizedLanguageOptions,
                    selection: languageBinding,
                    displayMapping: { key in
                        key == "English" ? Localizable.string(Localizable.english) : Localizable.string(Localizable.deutsch)
                    }
                )
                
                ToggleIconRow(
                    icon: "hand.tap.fill",
                    iconColor: .purple,
                    title: Localizable.string(Localizable.hapticFeedback),
                    isOn: $hapticFeedbackEnabled
                )
                
                MenuIconRow(
                    icon: "paintbrush.fill",
                    iconColor: .pink,
                    title: Localizable.string(Localizable.appearance),
                    options: localizedAppearanceOptions,
                    selection: $appearancePreference,
                    displayMapping: { key in
                        switch key {
                        case "Light": return Localizable.string(Localizable.light)
                        case "Dark": return Localizable.string(Localizable.dark)
                        default: return Localizable.string(Localizable.system)
                        }
                    }
                )
            }

            SwiftUI.Section {
                ToggleIconRow(
                    icon: "icloud.fill",
                    iconColor: .blue,
                    title: Localizable.string(Localizable.iCloudSync),
                    isOn: $iCloudSyncEnabled,
                    tintColor: .blue
                )
            } footer: {
                iCloudSyncSectionFooter()
            }
            
            SwiftUI.Section {
                // FAQ section - temporarily disabled, will be added in next update
                /*
                NavigationIconRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .blue,
                    title: Localizable.string(Localizable.faq)
                ) {
                    FAQView()
                }
                */
                
                Button {
                    HapticManager.shared.lightImpact()
                    if MFMailComposeViewController.canSendMail() {
                        showMailComposer = true
                    } else {
                        showMailUnavailableAlert = true
                    }
                } label: {
                    SettingsIconRow(
                        icon: "envelope.fill",
                        iconColor: .blue,
                        title: Localizable.string(Localizable.contactUs)
                    )
                }
                
                // Report a Bug - temporarily disabled, will be added in next update
                /*
                NavigationIconRow(
                    icon: "flag.fill",
                    iconColor: .orange,
                    title: Localizable.string(Localizable.reportABug)
                ) {
                    Text(Localizable.string(Localizable.reportABug))
                        .navigationTitle(Localizable.string(Localizable.reportABug))
                }
                */
            }
            
            SwiftUI.Section {
                Button {
                    HapticManager.shared.lightImpact()
                    presentingLegalURL = URL(string: "https://www.gizatech.de/hero-b2-beruf/impressum")
                } label: {
                    HStack {
                        SettingsIconRow(
                            icon: "building.2.fill",
                            iconColor: .gray,
                            title: Localizable.string(Localizable.impressum)
                        )
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Button {
                    HapticManager.shared.lightImpact()
                    presentingLegalURL = URL(string: "https://www.gizatech.de/hero-b2-beruf/terms-of-use")
                } label: {
                    HStack {
                        SettingsIconRow(
                            icon: "doc.text.fill",
                            iconColor: .gray,
                            title: Localizable.string(Localizable.termsOfUse)
                        )
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Button {
                    HapticManager.shared.lightImpact()
                    presentingLegalURL = URL(string: "https://www.gizatech.de/hero-b2-beruf/privacy-policy")
                } label: {
                    HStack {
                        SettingsIconRow(
                            icon: "lock.shield.fill",
                            iconColor: .gray,
                            title: Localizable.string(Localizable.privacyPolicy)
                        )
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            SwiftUI.Section {
                DestructiveIconRow(
                    icon: "arrow.counterclockwise",
                    title: Localizable.string(Localizable.resetApp)
                ) {
                    HapticManager.shared.lightImpact()
                    showResetAlert = true
                }
                
                // Debug: Reset to Fresh Install (Testing Only) - Deactivated for production
                // Button {
                //     HapticManager.shared.lightImpact()
                //     subscriptionManager.resetToFreshInstall()
                // } label: {
                //     SettingsIconRow(
                //         icon: "arrow.counterclockwise.circle.fill",
                //         iconColor: .blue,
                //         title: "Reset to Fresh Install"
                //     )
                // }
                // .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Localizable.string(Localizable.settings))
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                subject: "Contact - Hero. B2 - Berufsprachkurs",
                messageBody: getContactEmailBody(),
                toRecipients: ["info@gizatech.de"],
                onDismiss: {
                    showMailComposer = false
                }
            )
        }
        .alert(Localizable.string(Localizable.mailUnavailable), isPresented: $showMailUnavailableAlert) {
            Button(Localizable.string(Localizable.ok), role: .cancel) { }
        } message: {
            Text(Localizable.string(Localizable.mailUnavailableMessage))
        }
        .alert(Localizable.string(Localizable.resetAppTitle), isPresented: $showResetAlert) {
            Button(Localizable.string(Localizable.cancel), role: .cancel) { }
            Button(Localizable.string(Localizable.reset), role: .destructive) {
                resetApp()
            }
        } message: {
            Text(Localizable.string(Localizable.resetAppMessage))
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(item: Binding(
            get: { presentingLegalURL.map { LegalDocument(url: $0) } },
            set: { presentingLegalURL = $0?.url }
        )) { document in
            SettingsLegalWebSheetView(url: document.url)
        }
    }
    
    // Legal document identifier for sheet presentation
    struct LegalDocument: Identifiable {
        let url: URL
        var id: URL { url }
    }
    
    @ViewBuilder
    private func iCloudSyncSectionFooter() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localizable.string(Localizable.iCloudSyncFooter))
            if FileManager.default.ubiquityIdentityToken != nil {
                Text(Localizable.string(Localizable.iCloudAccountSignedIn))
            } else {
                Text(Localizable.string(Localizable.iCloudAccountNotSignedIn))
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }

    private func resetApp() {
        HapticManager.shared.mediumImpact()
        try? WordProgress.deleteAll(in: modelContext)
        try? CustomWordEntry.deleteAll(in: modelContext)
        dataService.resetAllData()
    }
    
    private func getContactEmailBody() -> String {
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        return """
        If you need help, please do not remove this info as it will help us to provide fast and quality support:
        
        ---
        
        App version: \(appVersion) (\(buildNumber))
        Device: \(deviceModel)
        iOS Version: \(systemVersion)
        
        Please describe your issue below this line.
        
        ---
        
        
        """
    }
}

// MARK: - Reusable Row Components

private struct SettingsIconRow: View {
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
        }
    }
}

private struct NavigationIconRow<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let showBadge: Bool
    let destination: () -> Destination
    
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil, showBadge: Bool = false, @ViewBuilder destination: @escaping () -> Destination) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.showBadge = showBadge
        self.destination = destination
    }
    
    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                SettingsIconRow(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle)
                Spacer()
                if showBadge {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .padding(.trailing, 4)
                }
            }
        }
    }
}

private struct ToggleIconRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    var tintColor: Color = .green
    
    var body: some View {
        HStack(spacing: 12) {
            SettingsIconRow(icon: icon, iconColor: iconColor, title: title)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(tintColor)
        }
    }
}

private struct MenuIconRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let options: [String]
    @Binding var selection: String
    var displayMapping: ((String) -> String)?
    
    init(icon: String, iconColor: Color, title: String, options: [String], selection: Binding<String>, displayMapping: ((String) -> String)? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.options = options
        self._selection = selection
        self.displayMapping = displayMapping
    }
    
    private func displayText(for key: String) -> String {
        displayMapping?(key) ?? key
    }
    
    var body: some View {
        HStack(spacing: 12) {
            SettingsIconRow(icon: icon, iconColor: iconColor, title: title)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(displayText(for: option))
                            if selection == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(displayText(for: selection))
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct DestructiveIconRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(role: .destructive, action: action) {
            SettingsIconRow(icon: icon, iconColor: .red, title: title)
        }
    }
}

private struct AboutRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

private extension SettingsView {
    var localizedLanguageOptions: [String] {
        ["English", "Deutsch"] // Keys
    }
    
    var localizedAppearanceOptions: [String] {
        ["Light", "Dark", "System"] // Keys
    }
    
    var localizedPeriodicityOptions: [String] {
        ["12_hours", "24_hours"] // Keys
    }
    
}

// MARK: - Premium Promo Section
private struct PremiumPromoSection: View {
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
        VStack(spacing: 0) {
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
                            .fixedSize(horizontal: false, vertical: true)
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
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(DataService())
    }
}

