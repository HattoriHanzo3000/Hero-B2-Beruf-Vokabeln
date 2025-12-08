//
//  SettingsView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    @EnvironmentObject var dataService: DataService
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("appearancePreference") private var appearancePreference = "System" // Stores key: "Light" | "Dark" | "System"
    @AppStorage("textSizePreference") private var textSizePreference = "Large" // Stores key: "Extra Small" | "Small" | etc.
    @AppStorage("appLanguage") private var appLanguage = "English" { // Stores key: "English" | "Deutsch"
        didSet {
            languageManager.setLanguage(appLanguage)
        }
    }
    @State private var showMailComposer = false
    @State private var showMailUnavailableAlert = false
    @State private var showResetAlert = false
    @State private var presentingLegalURL: URL? = nil
    @State private var showRewardedAdAlert = false
    @State private var rewardedAdMessage = ""
    @State private var showPaywall = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    // Premium status tracking
    @AppStorage("premiumUnlockedUntil") private var premiumUnlockedUntil: TimeInterval = 0
    @AppStorage("adsDisabledUntil") private var adsDisabledUntil: TimeInterval = 0
    
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
                isPremiumActive: isPremiumActive,
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
                
                NavigationIconRow(
                    icon: "gear.badge",
                    iconColor: .gray,
                    title: Localizable.string(Localizable.update)
                ) {
                    UpdateView()
                }
            }
            
            // Premium Features Section - Temporarily deactivated
            /*
            SwiftUI.Section {
                Button {
                    HapticManager.shared.mediumImpact()
                    showRewardedAd()
                } label: {
                    SettingsIconRow(
                        icon: "play.circle.fill",
                        iconColor: Color("AppGreen"),
                        title: "Watch Ad for Premium Features",
                        subtitle: isPremiumActive ? "Premium active until \(premiumExpiryText)" : "Unlock premium features for 1 hour"
                    )
                }
                .disabled(!AdManager.shared.canShowRewarded)
                .opacity(AdManager.shared.canShowRewarded ? 1.0 : 0.6)
            } header: {
                Text("Premium Features")
            } footer: {
                Text(isPremiumActive ? "Enjoy ad-free experience and all premium features!" : "Watch a short ad to unlock premium features for 1 hour. No ads, all features unlocked.")
            }
            */
            
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
                
                MenuIconRow(
                    icon: "textformat.size",
                    iconColor: .indigo,
                    title: Localizable.string(Localizable.displayAndTextSize),
                    options: localizedTextSizeOptions,
                    selection: $textSizePreference,
                    displayMapping: { key in
                        switch key {
                        case "Extra Small": return Localizable.string(Localizable.extraSmall)
                        case "Small": return Localizable.string(Localizable.small)
                        case "Medium": return Localizable.string(Localizable.medium)
                        case "Large": return Localizable.string(Localizable.large)
                        case "Extra Large": return Localizable.string(Localizable.extraLarge)
                        case "XX Large": return Localizable.string(Localizable.xxLarge)
                        case "XXX Large": return Localizable.string(Localizable.xxxLarge)
                        default: return Localizable.string(Localizable.large)
                        }
                    }
                )
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
                    SettingsIconRow(
                        icon: "building.2.fill",
                        iconColor: .gray,
                        title: Localizable.string(Localizable.impressum)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Button {
                    HapticManager.shared.lightImpact()
                    presentingLegalURL = URL(string: "https://www.gizatech.de/hero-b2-beruf/terms-of-use")
                } label: {
                    SettingsIconRow(
                        icon: "doc.text.fill",
                        iconColor: .gray,
                        title: Localizable.string(Localizable.termsOfUse)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Button {
                    HapticManager.shared.lightImpact()
                    presentingLegalURL = URL(string: "https://www.gizatech.de/hero-b2-beruf/privacy-policy")
                } label: {
                    SettingsIconRow(
                        icon: "lock.shield.fill",
                        iconColor: .gray,
                        title: Localizable.string(Localizable.privacyPolicy)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                
                // Debug: Deactivate Premium (Testing Only) - Hidden for production
                /*
                Button {
                    HapticManager.shared.lightImpact()
                    subscriptionManager.deactivatePremiumForTesting()
                } label: {
                    SettingsIconRow(
                        icon: "lock.slash.fill",
                        iconColor: .orange,
                        title: "Basis"
                    )
                }
                .buttonStyle(.plain)
                */
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            BannerAd()
                .background(Color(.systemGroupedBackground))
        }
        .navigationTitle(Localizable.string(Localizable.settings))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
        }
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
        .alert("Premium Unlocked!", isPresented: $showRewardedAdAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(rewardedAdMessage)
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
    
    private func resetApp() {
        HapticManager.shared.mediumImpact()
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
    let destination: () -> Destination
    
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil, @ViewBuilder destination: @escaping () -> Destination) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.destination = destination
    }
    
    var body: some View {
        NavigationLink(destination: destination()) {
            SettingsIconRow(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle)
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
    
    var localizedTextSizeOptions: [String] {
        ["Extra Small", "Small", "Medium", "Large", "Extra Large", "XX Large", "XXX Large"] // Keys
    }
    
    var localizedPeriodicityOptions: [String] {
        ["12_hours", "24_hours"] // Keys
    }
    
    // Premium features helpers
    var isPremiumActive: Bool {
        let now = Date().timeIntervalSince1970
        return premiumUnlockedUntil > now || 
               adsDisabledUntil > now || 
               PromoCodeManager.shared.isPremiumActive ||
               subscriptionManager.isPremiumActive
    }
    
    var premiumExpiryText: String {
        let expiryDate = Date(timeIntervalSince1970: max(premiumUnlockedUntil, adsDisabledUntil))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: expiryDate)
    }
    
    func showRewardedAd() {
        RewardedAdHelper.showRewardedAd {
            // User watched the ad - grant premium features for 1 hour
            let oneHourFromNow = Date().timeIntervalSince1970 + 3600 // 1 hour = 3600 seconds
            premiumUnlockedUntil = oneHourFromNow
            adsDisabledUntil = oneHourFromNow
            
            // Show success message
            rewardedAdMessage = "Premium features unlocked for 1 hour! Enjoy ad-free experience."
            showRewardedAdAlert = true
            
            HapticManager.shared.success()
        }
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
                    }
                    
                    Spacer()
                }
                
                // Button - only show when premium is not active
                if !isPremiumActive {
                    Button(action: onStartFreeTrial) {
                        Text(Localizable.string(Localizable.startFreeTrial))
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

