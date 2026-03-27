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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Mascot launch image
                Image("MascotLaunch")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, maxHeight: 200)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                
                // App description block with rounded corners
                VStack(alignment: .leading, spacing: 12) {
                    Text(Localizable.string(Localizable.aboutThisApp))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(Localizable.string(Localizable.aboutAppDescription))
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                
                Spacer()
                
                // Version info at bottom
                Text("\(Localizable.string(Localizable.version)) \(appVersion)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(16)
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
                    Button("Set Free Mode") {
                        subscriptionManager.deactivatePremiumForTesting()
                        HapticManager.shared.success()
                        lastAppliedMessage = "Free mode enabled"
                    }

                    Button("Set Premium Mode") {
                        subscriptionManager.activatePremiumForTesting()
                        HapticManager.shared.success()
                        lastAppliedMessage = "Premium mode enabled"
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
                    Text("Presets use uneven distributions to look natural across wrong, familiar, reinforced, and mastered.")
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

