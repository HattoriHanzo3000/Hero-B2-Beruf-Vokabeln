//
//  AppConfig.swift
//  B2 Berufssprachkurs
//
//  RevenueCat public API key: `Config/Shared.xcconfig` → `REVENUECAT_PUBLIC_API_KEY` → Info.plist
//  `RevenueCatAPIKey`. Fallback: env `REVENUECAT_API_KEY` (e.g. CI). Key is public client-side; committing
//  Shared.xcconfig keeps clones buildable without extra setup.
//

import Foundation

enum AppConfig {
    private static let revenueCatInfoPlistKey = "RevenueCatAPIKey"
    private static let revenueCatEnvKey = "REVENUECAT_API_KEY"

    /// RevenueCat **public** (App Store) API key — client-visible by design; still keep per-environment keys in build settings or CI.
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

    static func validateConfiguration() -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        let key = revenueCatAPIKey
        if key.isEmpty || key.contains("YOUR_") {
            errors.append("RevenueCat API key is not configured (Info.plist RevenueCatAPIKey / REVENUECAT_PUBLIC_API_KEY or env REVENUECAT_API_KEY).")
        }
        return (errors.isEmpty, errors)
    }

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
