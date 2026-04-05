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
    /// Stored values: `"English"` | `"Deutsch"`. Sync via `onAppear` / `onChange` — `@AppStorage` `didSet` does not run for `Binding` writes (e.g. menu selection).
    @AppStorage("appLanguage") private var appLanguage = "Deutsch"
    @State private var showMailComposer = false
    @State private var showMailUnavailableAlert = false
    @State private var showResetAlert = false
    @State private var presentingLegalURL: URL? = nil
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.settingsSubscriptionPreview) private var settingsSubscriptionPreview

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var legalWebItems: [(icon: String, title: String, url: URL)] {
        [
            ("building.2.fill", Localizable.string(Localizable.impressum), AppExternalLinks.legalImpressum),
            ("doc.text.fill", Localizable.string(Localizable.termsOfUse), AppExternalLinks.legalTermsOfUse),
            ("lock.shield.fill", Localizable.string(Localizable.privacyPolicy), AppExternalLinks.legalPrivacyPolicy),
        ]
    }

    var body: some View {
        List {
            SwiftUI.Section {
                NavigationIconRow(
                    icon: "info.circle.fill",
                    iconColor: .gray,
                    title: Localizable.string(Localizable.about)
                ) {
                    AboutView()
                }

                NavigationIconRow(
                    icon: "square.and.arrow.up",
                    iconColor: .blue,
                    title: Localizable.string(Localizable.share)
                ) {
                    ShareView()
                }
            } header: {
                Text(Localizable.string(Localizable.settingsSectionAbout))
            }

            SwiftUI.Section {
                NavigationIconRow(
                    icon: "creditcard.fill",
                    iconColor: Color("AppBlue"),
                    title: Localizable.string(Localizable.yourPlan),
                    subtitle: settingsSubscriptionPreview?.planStatusLine ?? subscriptionManager.localizedPlanStatusLine
                ) {
                    YourPlanView()
                        .environment(\.settingsSubscriptionPreview, settingsSubscriptionPreview)
                }
            } header: {
                Text(Localizable.string(Localizable.settingsSectionHeroPro))
            }

            SwiftUI.Section {
                MenuIconRow(
                    icon: "globe",
                    iconColor: .blue,
                    title: Localizable.string(Localizable.appLanguage),
                    options: localizedLanguageOptions,
                    selection: $appLanguage,
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
            } header: {
                Text(Localizable.string(Localizable.settingsSectionPersonalization))
            }

            SwiftUI.Section {
                ToggleIconRow(
                    icon: "icloud.fill",
                    iconColor: .blue,
                    title: Localizable.string(Localizable.iCloudSync),
                    isOn: $iCloudSyncEnabled,
                    tintColor: .blue
                )
            } header: {
                Text(Localizable.string(Localizable.settingsSectionSynchronization))
            } footer: {
                iCloudSyncSectionFooter()
            }

            SwiftUI.Section {
                SettingsExternalLinkRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .blue,
                    title: Localizable.string(Localizable.faq)
                ) {
                    HapticManager.shared.lightImpact()
                    presentingLegalURL = AppExternalLinks.faq
                }

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
            } header: {
                Text(Localizable.string(Localizable.settingsSectionSupport))
            }

            SwiftUI.Section {
                ForEach(legalWebItems, id: \.url) { item in
                    SettingsExternalLinkRow(
                        icon: item.icon,
                        iconColor: .gray,
                        title: item.title
                    ) {
                        HapticManager.shared.lightImpact()
                        presentingLegalURL = item.url
                    }
                }
            } header: {
                Text(Localizable.string(Localizable.settingsSectionLegal))
            }

            SwiftUI.Section {
                DestructiveIconRow(
                    icon: "arrow.counterclockwise",
                    title: Localizable.string(Localizable.resetApp)
                ) {
                    HapticManager.shared.lightImpact()
                    showResetAlert = true
                }
            } header: {
                Text(Localizable.string(Localizable.settingsSectionData))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(Localizable.string(Localizable.settings))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            languageManager.setLanguage(appLanguage)
        }
        .onChange(of: appLanguage) { _, newValue in
            languageManager.setLanguage(newValue)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                subject: Localizable.string(Localizable.contactUsEmailSubject),
                messageBody: contactEmailBody(),
                toRecipients: [AppExternalLinks.supportEmail],
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
        .sheet(item: Binding(
            get: { presentingLegalURL.map { LegalDocument(url: $0) } },
            set: { presentingLegalURL = $0?.url }
        )) { document in
            SettingsLegalWebSheetView(url: document.url)
        }
    }

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

    private func contactEmailBody() -> String {
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        return String(
            format: Localizable.string(Localizable.contactUsEmailBody),
            appVersion,
            buildNumber,
            deviceModel,
            systemVersion
        )
    }
}

private extension SettingsView {
    var localizedLanguageOptions: [String] {
        ["English", "Deutsch"]
    }

    var localizedAppearanceOptions: [String] {
        ["Light", "Dark", "System"]
    }
}

#Preview("Settings — live") {
    NavigationStack {
        SettingsView()
            .environmentObject(DataService())
    }
}

#Preview("Settings — free trial") {
    NavigationStack {
        SettingsView()
            .environmentObject(DataService())
            .environment(\.settingsSubscriptionPreview, .freeTrial)
    }
}

#Preview("Settings — monthly") {
    NavigationStack {
        SettingsView()
            .environmentObject(DataService())
            .environment(\.settingsSubscriptionPreview, .monthlySubscription)
    }
}

#Preview("Settings — lifetime") {
    NavigationStack {
        SettingsView()
            .environmentObject(DataService())
            .environment(\.settingsSubscriptionPreview, .lifetime)
    }
}
