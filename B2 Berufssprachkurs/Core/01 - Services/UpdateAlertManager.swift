//
//  UpdateAlertManager.swift
//  B2 Berufssprachkurs
//
//  Soft update prompt: compare bundle version to App Store, throttle to at most once per calendar day.
//

import Combine
import Foundation
import OSLog
import SwiftUI
import UIKit

@MainActor
final class UpdateAlertManager: ObservableObject {
    static let shared = UpdateAlertManager()

    @Published var showUpdateAlert = false
    @Published var availableVersion: String = ""
    @Published var appStoreURL: String = ""

    @AppStorage("lastUpdateAlertDate") private var lastUpdateAlertDate: TimeInterval = 0

    private init() {}

    func checkForUpdateAlert() async {
        guard shouldOfferUpdatePrompt() else {
            return
        }

        do {
            if let appInfo = try await AppStoreService.shared.fetchAppInfo() {
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                let storeVersion = appInfo.version

                if compareVersions(currentVersion, storeVersion) < 0 {
                    availableVersion = storeVersion
                    appStoreURL = AppStoreService.listingURL(preferredTrackId: appInfo.trackId)
                    showUpdateAlert = true
                    lastUpdateAlertDate = Date().timeIntervalSince1970
                }
            }
        } catch {
            AppLog.appUpdate.error("Fetch App Store version failed: \(error.localizedDescription)")
        }
    }

    /// At most one update prompt per calendar day (local timezone). `lastUpdateAlertDate == 0` always allows a check.
    private func shouldOfferUpdatePrompt() -> Bool {
        guard lastUpdateAlertDate > 0 else { return true }
        let lastShown = Date(timeIntervalSince1970: lastUpdateAlertDate)
        return !Calendar.current.isDateInToday(lastShown)
    }

    /// - Returns: `-1` if `version1` < `version2`, `0` if equal, `1` if greater.
    private func compareVersions(_ version1: String, _ version2: String) -> Int {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(v1Components.count, v2Components.count)

        for i in 0..<maxLength {
            let v1Value = i < v1Components.count ? v1Components[i] : 0
            let v2Value = i < v2Components.count ? v2Components[i] : 0

            if v1Value < v2Value {
                return -1
            } else if v1Value > v2Value {
                return 1
            }
        }

        return 0
    }

    func openAppStore() {
        guard let url = URL(string: appStoreURL) else { return }
        UIApplication.shared.open(url)
    }

    func remindMeLater() {
        showUpdateAlert = false
        // `lastUpdateAlertDate` stays set so we don’t prompt again until the next calendar day.
    }
}
