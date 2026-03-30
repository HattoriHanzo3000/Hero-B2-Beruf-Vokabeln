//
//  YourPlanView.swift
//  B2 Berufssprachkurs
//
//  Settings: current plan, tailored copy, manage subscription / paywall / restore.
//

import SwiftUI
import StoreKit
import UIKit

struct YourPlanView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.settingsSubscriptionPreview) private var settingsSubscriptionPreview
    @State private var showPaywall = false
    @State private var showManageSubscriptionFailed = false
    @State private var isRestoring = false

    var body: some View {
        List {
            SwiftUI.Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(effectivePlanStatusLine)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(detailBody)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let extra = supplementalDateLine {
                        Text(extra)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    if showsLifetimeThanks {
                        Text(Localizable.string(Localizable.planDetailLifetimeThanks))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 6)
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }

            SwiftUI.Section {
                if showsManageSubscription {
                    Button {
                        HapticManager.shared.lightImpact()
                        openManageSubscriptions()
                    } label: {
                        Text(Localizable.string(Localizable.manageSubscription))
                    }
                }
                if showsViewProPlans {
                    Button {
                        HapticManager.shared.lightImpact()
                        showPaywall = true
                    } label: {
                        Text(Localizable.string(Localizable.viewProPlans))
                    }
                }
                Button {
                    HapticManager.shared.lightImpact()
                    Task {
                        isRestoring = true
                        await subscriptionManager.restorePurchases()
                        isRestoring = false
                    }
                } label: {
                    HStack {
                        Text(Localizable.string(Localizable.restorePurchase))
                        if isRestoring {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isRestoring)
            }
        }
        .navigationTitle(Localizable.string(Localizable.yourPlan))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert(
            Localizable.string(Localizable.manageSubscriptionFailedTitle),
            isPresented: $showManageSubscriptionFailed
        ) {
            Button(Localizable.string(Localizable.ok), role: .cancel) { }
        } message: {
            Text(Localizable.string(Localizable.manageSubscriptionFailed))
        }
    }

    private var effectivePlanStatusLine: String {
        settingsSubscriptionPreview?.planStatusLine ?? subscriptionManager.localizedPlanStatusLine
    }

    private var showsLifetimeThanks: Bool {
        settingsSubscriptionPreview?.yourPlanShowsLifetimeThanks ?? subscriptionManager.hasLifetimeSubscription
    }

    private var showsManageSubscription: Bool {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanShowsManageSubscription
        }
        return subscriptionManager.hasActiveSubscription && !subscriptionManager.hasLifetimeSubscription
    }

    private var showsViewProPlans: Bool {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanShowsViewProPlans
        }
        return !subscriptionManager.hasLifetimeSubscription
    }

    private var detailBody: String {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanDetailBody
        }
        if !subscriptionManager.isPremiumActive {
            return Localizable.string(Localizable.planDetailFreeBody)
        }
        if subscriptionManager.hasLifetimeSubscription {
            return Localizable.string(Localizable.planDetailLifetimeBody)
        }
        if subscriptionManager.hasActiveSubscription {
            return Localizable.string(Localizable.planDetailSubscriptionBody)
        }
        if subscriptionManager.isLocalTrialActive {
            return Localizable.string(Localizable.planDetailTrialBody)
        }
        return Localizable.string(Localizable.planDetailSubscriptionBody)
    }

    private var supplementalDateLine: String? {
        if let preview = settingsSubscriptionPreview {
            return preview.yourPlanSupplementalDateLine
        }
        if subscriptionManager.isLocalTrialActive, let end = subscriptionManager.localTrialEndsAt {
            return String(format: Localizable.string(Localizable.planDetailTrialEndsFormat), formattedPlanDate(end))
        }
        if subscriptionManager.hasActiveSubscription,
           !subscriptionManager.hasLifetimeSubscription,
           let exp = subscriptionManager.premiumExpirationDate {
            return String(format: Localizable.string(Localizable.planDetailRenewsFormat), formattedPlanDate(exp))
        }
        return nil
    }

    private func formattedPlanDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        switch LanguageManager.shared.currentLanguage {
        case "Deutsch":
            formatter.locale = Locale(identifier: "de_DE")
        default:
            formatter.locale = Locale(identifier: "en_US")
        }
        return formatter.string(from: date)
    }

    private func openManageSubscriptions() {
        Task { @MainActor in
            guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
                showManageSubscriptionFailed = true
                return
            }
            do {
                try await AppStore.showManageSubscriptions(in: scene)
            } catch {
                showManageSubscriptionFailed = true
            }
        }
    }
}

#Preview("Your plan — live") {
    NavigationStack {
        YourPlanView()
    }
}

#Preview("Your plan — trial") {
    NavigationStack {
        YourPlanView()
            .environment(\.settingsSubscriptionPreview, .freeTrial)
    }
}

#Preview("Your plan — monthly") {
    NavigationStack {
        YourPlanView()
            .environment(\.settingsSubscriptionPreview, .monthlySubscription)
    }
}

#Preview("Your plan — lifetime") {
    NavigationStack {
        YourPlanView()
            .environment(\.settingsSubscriptionPreview, .lifetime)
    }
}
