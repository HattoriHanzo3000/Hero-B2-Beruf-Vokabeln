//
//  AdManager.swift
//  B2 Berufssprachkurs
//
//  Created for version 1.0.1
//

import Foundation
import Combine
import GoogleMobileAds

@MainActor
final class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()
    
    @Published var isInitialized = false
    @Published var canShowInterstitial = false
    @Published var canShowRewarded = false
    
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    
    private override init() {}
    
    func initialize() {
        guard !isInitialized else { return }
        
        // Application ID should be set in Info.plist as GADApplicationIdentifier
        // The SDK will read it automatically from there
        MobileAds.shared.start { [weak self] status in
            Task { @MainActor [weak self] in
                self?.isInitialized = true
                print("AdMob initialized with status: \(status.adapterStatusesByClassName)")
                
                // Preload ads after initialization
                self?.loadInterstitialAd()
                self?.loadRewardedAd()
            }
        }
    }
    
    func loadInterstitialAd() {
        let request = Request()
        InterstitialAd.load(with: AdMobConfig.currentInterstitialAdUnitID,
                           request: request) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                if let error = error {
                    print("Failed to load interstitial ad: \(error.localizedDescription)")
                    self?.canShowInterstitial = false
                    return
                }
                
                self?.interstitialAd = ad
                self?.canShowInterstitial = true
                
                // Set delegate
                self?.interstitialAd?.fullScreenContentDelegate = self
            }
        }
    }
    
    func showInterstitialAd(from viewController: UIViewController) {
        guard canShowInterstitial, let ad = interstitialAd else {
            print("Interstitial ad not ready")
            loadInterstitialAd() // Try to load for next time
            return
        }
        
        ad.present(from: viewController)
        canShowInterstitial = false
        interstitialAd = nil
        
        // Preload next ad
        loadInterstitialAd()
    }
    
    func loadRewardedAd() {
        let request = Request()
        RewardedAd.load(with: AdMobConfig.currentRewardedAdUnitID,
                      request: request) { [weak self] ad, error in
            Task { @MainActor [weak self] in
                if let error = error {
                    print("Failed to load rewarded ad: \(error.localizedDescription)")
                    self?.canShowRewarded = false
                    return
                }
                
                self?.rewardedAd = ad
                self?.canShowRewarded = true
                
                // Set delegate
                self?.rewardedAd?.fullScreenContentDelegate = self
            }
        }
    }
    
    func showRewardedAd(from viewController: UIViewController, 
                       onRewardEarned: @escaping () -> Void) {
        guard canShowRewarded, let ad = rewardedAd else {
            print("Rewarded ad not ready")
            loadRewardedAd() // Try to load for next time
            return
        }
        
        ad.present(from: viewController, userDidEarnRewardHandler: {
            // Reward the user
            let reward = ad.adReward
            print("User earned reward: \(reward.amount) \(reward.type)")
            onRewardEarned()
        })
        
        canShowRewarded = false
        rewardedAd = nil
        
        // Preload next ad
        loadRewardedAd()
    }
}

extension AdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad dismissed")
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present: \(error.localizedDescription)")
        loadInterstitialAd()
        loadRewardedAd()
    }
}

