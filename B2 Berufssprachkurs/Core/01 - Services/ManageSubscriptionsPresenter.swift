//
//  ManageSubscriptionsPresenter.swift
//  B2 Berufssprachkurs
//
//  Presents the system manage-subscriptions flow and reports success.
//  Created: 05.04.26.
//

import StoreKit
import UIKit

// MARK: - ManageSubscriptionsPresenter

enum ManageSubscriptionsPresenter {
    /// Presents the system subscription management UI. Returns `false` if no window scene or StoreKit fails.
    @MainActor
    static func presentSystemManageSubscriptions() async -> Bool {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return false
        }
        do {
            try await AppStore.showManageSubscriptions(in: scene)
            return true
        } catch {
            return false
        }
    }
}
