//
//  CockpitProgressSection.swift
//  B2 Berufssprachkurs
//
//  Progress card with scope picker and statistics wheel.
//

import SwiftUI

struct CockpitProgressSection: View {
    @Binding var progressWordScopeRaw: String
    var dataService: DataService
    var reduceMotion: Bool
    /// Pass `true` for canvas previews only; `nil` uses live subscription state via parent.
    var isPremiumPreviewOverride: Bool?

    private var progressWordScope: DataService.ProgressWordScope {
        DataService.ProgressWordScope(rawValue: progressWordScopeRaw) ?? .app
    }

    private var progressWordScopeBinding: Binding<DataService.ProgressWordScope> {
        Binding(
            get: { progressWordScope },
            set: { newValue in
                progressWordScopeRaw = newValue.rawValue
                HapticManager.shared.selection()
            }
        )
    }

    private var progressSubtitleAnimationKey: String {
        "\(progressWordScope.rawValue)|\(dataService.getBundleWordIds().count)|\(dataService.getUserCustomWordIds().count)"
    }

    var body: some View {
        CockpitCard(
            titleIcon: "chart.line.uptrend.xyaxis",
            title: Localizable.string(Localizable.progress),
            subtitle: AnyView(
                Text(
                    String(
                        format: Localizable.string(
                            progressWordScope == .app
                                ? Localizable.progressDescription
                                : Localizable.progressDescriptionMyWords
                        ),
                        progressWordScope == .app
                            ? dataService.getBundleWordIds().count
                            : dataService.getUserCustomWordIds().count
                    )
                )
                .monospacedDigit()
                .contentTransition(reduceMotion ? .interpolate : .numericText())
                .animation(reduceMotion ? .default : .smooth(duration: 0.45), value: progressSubtitleAnimationKey)
            ),
            titleTrailing: AnyView(
                Picker(selection: progressWordScopeBinding) {
                    Text(Localizable.string(Localizable.progressWordScopeApp))
                        .tag(DataService.ProgressWordScope.app)
                    Text(Localizable.string(Localizable.progressWordScopeMine))
                        .tag(DataService.ProgressWordScope.mine)
                } label: {
                    EmptyView()
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 168)
                .accessibilityLabel(Localizable.string(Localizable.progress))
            )
        ) {
            ProgressStatisticsView(
                dataService: dataService,
                statisticsPreviewPreset: isPremiumPreviewOverride == true ? .p67 : nil,
                wordScope: progressWordScope
            )
            .padding(.top, 2)
        }
        .padding(.horizontal)
    }
}
