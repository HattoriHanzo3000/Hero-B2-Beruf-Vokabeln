//
//  DebugOverrides.swift
//  B2 Berufssprachkurs
//
//  DEBUG-only overrides for subscription state. Used by launch schemes and About → Debug.
//

#if DEBUG
import Foundation

enum DebugOverrides {
    static let simulateProKey = "debugSimulatePro"

    /// When non-nil, overrides premium status. `nil` = use real RevenueCat / trial state.
    static var simulatePro: Bool? {
        get {
            guard UserDefaults.standard.object(forKey: simulateProKey) != nil else {
                return nil
            }
            return UserDefaults.standard.bool(forKey: simulateProKey)
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: simulateProKey)
            } else {
                UserDefaults.standard.removeObject(forKey: simulateProKey)
            }
        }
    }

    static func clearAll() {
        simulatePro = nil
    }
}
#endif
