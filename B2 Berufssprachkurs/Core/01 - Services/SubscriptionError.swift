//
//  SubscriptionError.swift
//  B2 Berufssprachkurs
//
//  Typed subscription and purchase errors with user-facing mapping.
//  Created: 06.04.26.
//

import Foundation

// MARK: - SubscriptionError

enum SubscriptionError: LocalizedError {
    case productNotLoaded
    case userCancelled
    case transactionUnverified
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotLoaded:
            return "Product information is not available. Please try again."
        case .userCancelled:
            return "Purchase was cancelled."
        case .transactionUnverified:
            return "Transaction could not be verified."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
