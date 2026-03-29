//
//  UpdateAlertManager.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class UpdateAlertManager: ObservableObject {
    static let shared = UpdateAlertManager()
    
    @Published var showUpdateAlert = false
    @Published var availableVersion: String = ""
    @Published var appStoreURL: String = ""
    
    @AppStorage("lastUpdateAlertDate") private var lastUpdateAlertDate: TimeInterval = 0
    
    private init() {}
    
    /// Checks if an update is available and if the alert should be shown
    func checkForUpdateAlert() async {
        // Check if we should show the alert (once per day)
        guard shouldShowAlert() else {
            return
        }
        
        do {
            if let appInfo = try await AppStoreService.shared.fetchAppInfo() {
                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                let storeVersion = appInfo.version
                
                // Compare versions
                if compareVersions(currentVersion, storeVersion) < 0 {
                    availableVersion = storeVersion
                    appStoreURL = AppStoreService.listingURL(preferredTrackId: appInfo.trackId)
                    showUpdateAlert = true
                    lastUpdateAlertDate = Date().timeIntervalSince1970
                }
            }
        } catch {
            // Silently fail
            print("Failed to check for update: \(error.localizedDescription)")
        }
    }
    
    /// Determines if the alert should be shown (once per day)
    private func shouldShowAlert() -> Bool {
        let lastDate = Date(timeIntervalSince1970: lastUpdateAlertDate)
        let calendar = Calendar.current
        
        // Check if last alert was shown today
        if calendar.isDateInToday(lastDate) {
            return false
        }
        
        // Check if last alert was shown more than 24 hours ago
        if let hoursSinceLastAlert = calendar.dateComponents([.hour], from: lastDate, to: Date()).hour {
            return hoursSinceLastAlert >= 24
        }
        
        return true
    }
    
    /// Compares two version strings
    /// Returns: -1 if version1 < version2, 0 if equal, 1 if version1 > version2
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
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
    
    func remindMeLater() {
        showUpdateAlert = false
        // Don't update lastUpdateAlertDate so it can show again tomorrow
    }
}
