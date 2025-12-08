//
//  BannerAdView.swift
//  B2 Berufssprachkurs
//
//  Created for version 1.0.1
//

import SwiftUI
import GoogleMobileAds
import UIKit

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        
        // Get root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            banner.rootViewController = rootViewController
        }
        
        let request = Request()
        banner.load(request)
        
        return banner
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // No updates needed
    }
}

// SwiftUI wrapper for easy use
struct BannerAd: View {
    @AppStorage("adsDisabledUntil") private var adsDisabledUntil: TimeInterval = 0
    @ObservedObject private var promoCodeManager = PromoCodeManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    private var isPremiumActive: Bool {
        let now = Date().timeIntervalSince1970
        return adsDisabledUntil > now || 
               promoCodeManager.isPremiumActive || 
               subscriptionManager.isPremiumActive
    }
    
    var body: some View {
        // Check if AdMob is enabled and user doesn't have premium
        if AdMobConfig.isEnabled && !isPremiumActive {
            BannerAdView(adUnitID: AdMobConfig.currentBannerAdUnitID)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
        }
    }
}

