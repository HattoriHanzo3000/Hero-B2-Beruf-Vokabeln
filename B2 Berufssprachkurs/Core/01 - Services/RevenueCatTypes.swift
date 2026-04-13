//
//  RevenueCatTypes.swift
//  B2 Berufssprachkurs
//
//  Shared RevenueCat-related types used across purchase flows.
//  Created: 05.04.26.
//

import Foundation

// MARK: - SubscriptionStatus

enum SubscriptionStatus {
    case none
    case active
    case expired
    case gracePeriod
}

enum RevenueCatError: LocalizedError {
    case notInitialized
    case userCancelled
    case purchaseFailed(String)
    case customerInfoUnavailable
    case offeringUnavailable
    case packageNotFound(String)

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "RevenueCat SDK is not initialized"
        case .userCancelled:
            return "Purchase was cancelled by the user"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .customerInfoUnavailable:
            return "Customer information is not available"
        case .offeringUnavailable:
            return "No offering is currently available"
        case .packageNotFound(let identifier):
            return "Package '\(identifier)' not found in current offering"
        }
    }
}
