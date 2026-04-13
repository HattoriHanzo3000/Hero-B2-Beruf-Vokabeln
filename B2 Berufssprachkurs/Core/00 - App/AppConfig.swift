//
//  AppConfig.swift
//  B2 Berufssprachkurs
//
//  App-wide configuration helpers and environment-based key resolution.
//  Created: 24.03.26.
//

import Foundation

// MARK: - App Configuration

enum AppConfig {
    // MARK: Keys

    private static let revenueCatInfoPlistKey = "RevenueCatAPIKey"
    private static let revenueCatEnvKey = "REVENUECAT_API_KEY"

    // MARK: RevenueCat

    /// Resolves the public RevenueCat key from Info.plist first, then environment.
    static var revenueCatAPIKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: revenueCatInfoPlistKey) as? String {
            let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.contains("$(") {
                return trimmed
            }
        }
        if let key = ProcessInfo.processInfo.environment[revenueCatEnvKey] {
            let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return ""
    }

    // MARK: Validation

    static func validateConfiguration() -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        let key = revenueCatAPIKey
        if key.isEmpty || key.contains("YOUR_") {
            errors.append("RevenueCat API key is not configured (Info.plist RevenueCatAPIKey / REVENUECAT_PUBLIC_API_KEY or env REVENUECAT_API_KEY).")
        }
        return (errors.isEmpty, errors)
    }

    // MARK: Diagnostics

    static func configurationSource() -> [String: String] {
        if let raw = Bundle.main.object(forInfoDictionaryKey: revenueCatInfoPlistKey) as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.contains("$(") {
                return ["RevenueCat": "Info.plist"]
            }
        }
        if let env = ProcessInfo.processInfo.environment[revenueCatEnvKey],
           !env.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ["RevenueCat": "Environment"]
        }
        if let raw = Bundle.main.object(forInfoDictionaryKey: revenueCatInfoPlistKey) as? String, raw.contains("$(") {
            return ["RevenueCat": "Info.plist (unresolved REVENUECAT_PUBLIC_API_KEY)"]
        }
        return ["RevenueCat": "Missing"]
    }
}
