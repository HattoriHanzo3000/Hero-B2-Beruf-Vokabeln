//
//  RewardedAdHelper.swift
//  B2 Berufssprachkurs
//
//  Created for version 1.0.1
//

import SwiftUI
import UIKit

struct RewardedAdHelper {
    static func showRewardedAd(onRewardEarned: @escaping () -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Could not find root view controller")
            return
        }
        
        AdManager.shared.showRewardedAd(from: rootViewController, onRewardEarned: onRewardEarned)
    }
}

