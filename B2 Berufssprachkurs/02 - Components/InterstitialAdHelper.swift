//
//  InterstitialAdHelper.swift
//  B2 Berufssprachkurs
//
//  Created for version 1.0.1
//

import SwiftUI
import UIKit

struct InterstitialAdHelper {
    static func showInterstitialAd() {
        // Check if user has premium subscription
        if SubscriptionManager.shared.isPremiumActive {
            return
        }
        
        // Check promo code premium status
        if PromoCodeManager.shared.isPremiumActive {
            return
        }
        
        // Check temporary ad disabling
        let adsDisabledUntil = UserDefaults.standard.double(forKey: "adsDisabledUntil")
        let now = Date().timeIntervalSince1970
        if adsDisabledUntil > now {
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Could not find root view controller")
            return
        }
        
        AdManager.shared.showInterstitialAd(from: rootViewController)
    }
}

