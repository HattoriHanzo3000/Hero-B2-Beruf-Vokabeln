//
//  AboutDebugSheet.swift
//  B2 Berufssprachkurs
//

#if DEBUG

import SwiftUI

struct AboutDebugSheet: View {
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
                    debugProgressButton(for: .p93)
                } header: {
                    Text(Localizable.string(Localizable.aboutDebugSectionProgressPresets))
                } footer: {
                    Text(Localizable.string(Localizable.aboutDebugProgressPresetFooter))
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
        }
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
