//
//  AboutDebugSheet.swift
//  B2 Berufssprachkurs
//

#if DEBUG

import SwiftData
import SwiftUI

struct AboutDebugSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var dataService: DataService
    @ObservedObject var subscriptionManager: SubscriptionManager
    @AppStorage(MyWordsDebugMockData.appStorageKey) private var isMockDataEnabled = false
    @AppStorage(GeneralWordsSection1AMockTranslations.appStorageKey) private var isGeneralWords1AMockTranslationsEnabled = false
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

                    Button(Localizable.string(Localizable.aboutDebugSetFreeMode)) {
                        subscriptionManager.deactivatePremiumForTesting()
                        HapticManager.shared.success()
                        lastAppliedMessage = Localizable.string(Localizable.aboutDebugFreeModeEnabled)
                    }

                    Button(Localizable.string(Localizable.aboutDebugSetProMode)) {
                        subscriptionManager.activatePremiumForTesting()
                        HapticManager.shared.success()
                        lastAppliedMessage = Localizable.string(Localizable.aboutDebugProModeEnabled)
                    }
                } header: {
                    Text(Localizable.string(Localizable.aboutDebugSectionSubscription))
                }

                SwiftUI.Section {
                    debugProgressButton(for: .p25)
                    debugProgressButton(for: .p44)
                    debugProgressButton(for: .p67)
                    debugProgressButton(for: .p84)
                    debugProgressButton(for: .p93)
                } header: {
                    Text(Localizable.string(Localizable.aboutDebugSectionProgressPresets))
                } footer: {
                    Text(Localizable.string(Localizable.aboutDebugProgressPresetFooter))
                }

                SwiftUI.Section {
                    Toggle(
                        Localizable.string(Localizable.aboutDebugMyWordsMockToggle),
                        isOn: $isMockDataEnabled
                    )
                    .onChange(of: isMockDataEnabled) { _, newValue in
                        applyMyWordsMockToggle(newValue)
                    }
                } header: {
                    Text(Localizable.string(Localizable.aboutDebugSectionMyWordsMock))
                } footer: {
                    Text(Localizable.string(Localizable.aboutDebugMyWordsMockFooter))
                }

                SwiftUI.Section {
                    Toggle(
                        Localizable.string(Localizable.aboutDebugGeneralWords1AMockToggle),
                        isOn: $isGeneralWords1AMockTranslationsEnabled
                    )
                    .onChange(of: isGeneralWords1AMockTranslationsEnabled) { _, newValue in
                        applyGeneralWords1AMockToggle(newValue)
                    }
                } header: {
                    Text(Localizable.string(Localizable.aboutDebugSectionGeneralWords1AMock))
                } footer: {
                    Text(Localizable.string(Localizable.aboutDebugGeneralWords1AMockFooter))
                }

                if let message = lastAppliedMessage {
                    SwiftUI.Section {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text(Localizable.string(Localizable.aboutDebugSectionLastAction))
                    }
                }
            }
            .navigationTitle(Localizable.string(Localizable.aboutDebugSheetTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .navigationBarSymbolStyle()
                    }
                    .accessibilityLabel(Text(Localizable.string(Localizable.cancel)))
                }
            }
            .onAppear {
                if isMockDataEnabled {
                    do {
                        try MyWordsDebugMockData.insertMissingMocks(in: modelContext)
                        lastAppliedMessage = nil
                    } catch {
                        lastAppliedMessage = String(
                            format: Localizable.string(Localizable.aboutDebugMyWordsMockErrorFormat),
                            error.localizedDescription
                        )
                    }
                }
                GeneralWordsSection1AMockTranslations.syncIfNeeded(
                    isEnabled: isGeneralWords1AMockTranslationsEnabled,
                    modelContext: modelContext
                )
            }
        }
    }

    private func applyMyWordsMockToggle(_ enabled: Bool) {
        do {
            if enabled {
                try MyWordsDebugMockData.insertMissingMocks(in: modelContext)
            } else {
                try MyWordsDebugMockData.removeAllMocks(dataService: dataService, modelContext: modelContext)
            }
            lastAppliedMessage = nil
            HapticManager.shared.success()
        } catch {
            lastAppliedMessage = String(
                format: Localizable.string(Localizable.aboutDebugMyWordsMockErrorFormat),
                error.localizedDescription
            )
            HapticManager.shared.lightImpact()
        }
    }

    private func applyGeneralWords1AMockToggle(_ enabled: Bool) {
        GeneralWordsSection1AMockTranslations.applyEnabled(enabled, modelContext: modelContext)
        lastAppliedMessage = nil
        HapticManager.shared.success()
    }

    @ViewBuilder
    private func debugProgressButton(for preset: SpacedRepetitionService.DebugProgressPreset) -> some View {
        Button {
            let actual = SpacedRepetitionService.shared.applyDebugProgressPreset(
                preset,
                allWordIds: dataService.getAllWordIds()
            )
            HapticManager.shared.success()
            lastAppliedMessage = String(
                format: Localizable.string(Localizable.aboutDebugAppliedPresetResult),
                preset.targetPercentage,
                actual
            )
        } label: {
            Text(
                String(
                    format: Localizable.string(Localizable.aboutDebugApplyProgressPreset),
                    preset.targetPercentage
                )
            )
        }
    }
}

#endif
