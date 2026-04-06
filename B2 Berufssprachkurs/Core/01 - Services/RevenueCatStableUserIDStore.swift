//
//  RevenueCatStableUserIDStore.swift
//  B2 Berufssprachkurs
//
//  Persists a stable RevenueCat app user id in Keychain to keep entitlements
//  consistent across launches and app rebuilds on the same device.
//

import Foundation
import Security

enum RevenueCatStableUserIDStore {
    private static let service = "com.hero.berufssprachkurs.revenuecat"
    private static let account = "stable_app_user_id"

    static func getOrCreate() -> String {
        if let existing = read() {
            return existing
        }
        let newID = UUID().uuidString.lowercased()
        save(newID)
        return newID
    }

    private static func read() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let id = String(data: data, encoding: .utf8),
              !id.isEmpty else {
            return nil
        }
        return id
    }

    private static func save(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        var insert = query
        insert[kSecValueData] = data
        _ = SecItemAdd(insert as CFDictionary, nil)
    }
}
