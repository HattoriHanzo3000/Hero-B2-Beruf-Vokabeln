//
//  HeroEinburgerungStorePresentation.swift
//  B2 Berufssprachkurs
//
//  Presents the cross-promo App Store product page for Hero Einburgerungstest.
//  Created: 04.04.26.
//

import StoreKit
import UIKit

enum HeroEinburgerungAppStore {
    /// App Store ID for “Hero – Einbürgerungstest” (`AppExternalLinks.CrossPromo.einburgerungAppStoreURL`).
    static let productID = NSNumber(value: AppExternalLinks.CrossPromo.einburgerungAppStoreNumericID)
    static let iTunesLookupAppID = AppExternalLinks.CrossPromo.einburgerungAppStoreNumericID
}

// MARK: - SKStoreProductViewController (single UIKit modal from topmost VC — no SwiftUI fullScreenCover)

enum HeroEinburgerungStorePresentation {
    private static var retainedDelegate: EinburgerungStoreProductDelegate?

    /// Presents `SKStoreProductViewController` once from `UIApplication.shared.b2_topMostViewController` after `loadProduct` succeeds.
    @MainActor
    static func present() {
        guard let presenter = UIApplication.shared.b2_topMostViewController else { return }

        HapticManager.shared.lightImpact()

        let storeVC = SKStoreProductViewController()
        let delegate = EinburgerungStoreProductDelegate {
            retainedDelegate = nil
        }
        retainedDelegate = delegate
        storeVC.delegate = delegate

        let params: [String: Any] = [
            SKStoreProductParameterITunesItemIdentifier: HeroEinburgerungAppStore.productID
        ]
        storeVC.loadProduct(withParameters: params) { loaded, _ in
            DispatchQueue.main.async {
                if loaded {
                    presenter.present(storeVC, animated: true)
                } else {
                    retainedDelegate = nil
                }
            }
        }
    }
}

final class EinburgerungStoreProductDelegate: NSObject, SKStoreProductViewControllerDelegate {
    private let onTeardown: () -> Void

    init(onTeardown: @escaping () -> Void) {
        self.onTeardown = onTeardown
    }

    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true) { [onTeardown] in
            onTeardown()
        }
    }
}
