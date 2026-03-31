//
//  AboutView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var dataService: DataService
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var versionTapCount = 0
    @State private var showDebugSheet = false

    // Get current app version (without build number)
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var aboutDescriptionText: Text {
        Text(Localizable.string(Localizable.aboutAppDescLead))
            + Text(Localizable.string(Localizable.aboutOfficialTestName))
                .fontWeight(.bold)
            + Text(Localizable.string(Localizable.aboutAppDescMid))
            + Text(Localizable.string(Localizable.aboutOfficialBookTitle))
                .fontWeight(.bold)
            + Text(Localizable.string(Localizable.aboutAppDescTail))
    }

    var body: some View {
        ZStack {
            PaywallBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image("MascotLaunch")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                    aboutDescriptionText
                        .font(.body)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    Text("\(Localizable.string(Localizable.version)) \(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            versionTapCount += 1
                            if versionTapCount >= 7 {
                                versionTapCount = 0
                                HapticManager.shared.mediumImpact()
                                showDebugSheet = true
                            }
                        }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.clear)
        }
        .navigationTitle(Localizable.string(Localizable.about))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDebugSheet) {
            AboutDebugSheet(
                dataService: dataService,
                subscriptionManager: subscriptionManager
            )
        }
    }
}

private struct AboutDebugSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataService: DataService
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var lastAppliedMessage: String?

    var body: some View {
        NavigationStack {
            List {
                SwiftUI.Section {
                    Button(Localizable.string(Localizable.aboutDebugRestoreNormalSubscription)) {
                        Task { @MainActor in
                            await subscriptionManager.restoreNormalSubscriptionStateForTesting()
                            let hadSnapshot = SpacedRepetitionService.shared.restoreStudyDataFromBeforeDebugPresets()
                            HapticManager.shared.success()
                            lastAppliedMessage = Localizable.string(
                                hadSnapshot ? Localizable.aboutDebugNormalModeRestoredAll : Localizable.aboutDebugNormalModeClearedStudy
                            )
                        }
                    }

                    Button("Set Free Mode") {
                        subscriptionManager.deactivatePremiumForTesting()
                        HapticManager.shared.success()
                        lastAppliedMessage = "Free mode enabled"
                    }

                    Button(Localizable.string(Localizable.aboutDebugSetProMode)) {
                        subscriptionManager.activatePremiumForTesting()
                        HapticManager.shared.success()
                        lastAppliedMessage = Localizable.string(Localizable.aboutDebugProModeEnabled)
                    }
                } header: {
                    Text("Subscription State")
                }

                SwiftUI.Section {
                    debugProgressButton(for: .p25)
                    debugProgressButton(for: .p44)
                    debugProgressButton(for: .p67)
                    debugProgressButton(for: .p93)
                } header: {
                    Text("Progress Presets")
                } footer: {
                    Text(Localizable.string(Localizable.aboutDebugProgressPresetFooter))
                }

                if let message = lastAppliedMessage {
                    SwiftUI.Section {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Last Action")
                    }
                }
            }
            .navigationTitle("Debug Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .navigationBarSymbolStyle()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func debugProgressButton(for preset: SpacedRepetitionService.DebugProgressPreset) -> some View {
        Button("Apply \(preset.targetPercentage)% Progress") {
            let actual = SpacedRepetitionService.shared.applyDebugProgressPreset(
                preset,
                allWordIds: dataService.getAllWordIds()
            )
            HapticManager.shared.success()
            lastAppliedMessage = "Applied \(preset.targetPercentage)% preset (current readiness: \(actual)%)"
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
            .environmentObject(DataService())
    }
}

