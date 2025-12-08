//
//  AdMobConfig.swift
//  B2 Berufssprachkurs
//
//  Created for version 1.0.1
//

import Foundation
import Combine

struct AdMobConfig {
    // MARK: - AdMob Enable/Disable Flag
    // Set to false to temporarily disable all AdMob functionality (banners, interstitials, rewarded)
    static let isEnabled = false
    
    // App ID from AdMob dashboard
    static let appID = "ca-app-pub-1380989901130305~8662057835"
    
    // Ad Unit IDs from AdMob dashboard
    static let bannerAdUnitID = "ca-app-pub-1380989901130305/2047837584" // Main Screens Banner
    static let interstitialAdUnitID = "ca-app-pub-1380989901130305/7780221009" // After Study Sessions
    static let rewardedAdUnitID = "ca-app-pub-1380989901130305/9000258748" // Premium Features
    
    // Test Ad Unit IDs (use these during development)
    // These are Google's official test ad unit IDs
    static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    static let testInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    static let testRewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    
    // Use test ads in debug mode
    #if DEBUG
    static let useTestAds = true
    #else
    static let useTestAds = false
    #endif
    
    static var currentBannerAdUnitID: String {
        useTestAds ? testBannerAdUnitID : bannerAdUnitID
    }
    
    static var currentInterstitialAdUnitID: String {
        useTestAds ? testInterstitialAdUnitID : interstitialAdUnitID
    }
    
    static var currentRewardedAdUnitID: String {
        useTestAds ? testRewardedAdUnitID : rewardedAdUnitID
    }
}

