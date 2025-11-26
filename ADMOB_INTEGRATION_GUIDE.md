# AdMob Integration Guide - Version 1.0.1

This guide provides step-by-step instructions for integrating Google AdMob into the Hero - Deutsch B2 Beruf iOS app.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Step 1: Create Google AdMob Account](#step-1-create-google-admob-account)
3. [Step 2: Add AdMob SDK via Swift Package Manager](#step-2-add-admob-sdk-via-swift-package-manager)
4. [Step 3: Configure App ID and Ad Unit IDs](#step-3-configure-app-id-and-ad-unit-ids)
5. [Step 4: Update Info.plist for Privacy](#step-4-update-infoplist-for-privacy)
6. [Step 5: Create AdManager Service](#step-5-create-admanager-service)
7. [Step 6: Create SwiftUI Ad Wrapper Views](#step-6-create-swiftui-ad-wrapper-views)
8. [Step 7: Integrate Ads into Views](#step-7-integrate-ads-into-views)
9. [Step 8: Implement App Tracking Transparency](#step-8-implement-app-tracking-transparency)
10. [Step 9: Testing with Test Ads](#step-9-testing-with-test-ads)
11. [Step 10: Best Practices & Guidelines](#step-10-best-practices--guidelines)

---

## Prerequisites

- Xcode 15.0 or later
- iOS 18.1+ deployment target (already configured)
- Google account for AdMob
- App Store Connect account (for production ads)

---

## Step 1: Create Google AdMob Account

1. **Visit Google AdMob**
   - Go to https://admob.google.com
   - Sign in with your Google account

2. **Create AdMob Account**
   - Click "Get Started"
   - Accept terms and conditions
   - Complete account setup

3. **Add Your App**
   - Click "Apps" in the left sidebar
   - Click "Add App"
   - Select "iOS"
   - Enter app name: "Hero - Deutsch B2 Beruf"
   - Bundle ID: `com.gizatech.B2-Beruf`
   - Click "Add App"

4. **Create Ad Units**
   You'll need to create ad units for different ad types:
   
   **Banner Ad Unit:**
   - Name: "Home Banner Ad"
   - Format: Banner
   - Click "Create Ad Unit"
   - **Save the Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`)
   
   **Interstitial Ad Unit:**
   - Name: "Interstitial Ad"
   - Format: Interstitial
   - Click "Create Ad Unit"
   - **Save the Ad Unit ID**
   
   **Rewarded Ad Unit (Optional):**
   - Name: "Rewarded Ad"
   - Format: Rewarded
   - Click "Create Ad Unit"
   - **Save the Ad Unit ID**

5. **Get Your App ID**
   - In AdMob dashboard, go to "Apps"
   - Find your app
   - **Copy the App ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`)

---

## Step 2: Add AdMob SDK via Swift Package Manager

1. **Open Xcode Project**
   - Open `B2 Berufssprachkurs.xcodeproj` in Xcode

2. **Add Package Dependency**
   - In Xcode, go to: **File → Add Package Dependencies...**
   - Enter URL: `https://github.com/googleads/swift-package-manager-google-mobile-ads.git`
   - Click "Add Package"
   - Select version: **Latest** (or specific version like 11.0.0)
   - Click "Add Package"
   - Select your target: **B2 Berufssprachkurs**
   - Click "Add Package"

3. **Verify Installation**
   - Check that `GoogleMobileAds` appears in your project navigator under "Package Dependencies"

---

## Step 3: Configure App ID and Ad Unit IDs

1. **Create Configuration File**
   - Create a new file: `B2 Berufssprachkurs/01 - Services/AdMobConfig.swift`
   - This file will store your AdMob configuration

2. **Add Configuration Constants**
   ```swift
   import Foundation
   
   struct AdMobConfig {
       // App ID from AdMob dashboard
       static let appID = "ca-app-pub-1380989901130305~8662057835"
       
       // Replace with your actual Ad Unit IDs
       static let bannerAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
       static let interstitialAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
       static let rewardedAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
       
       // Test Ad Unit IDs (use these during development)
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
   ```

---

## Step 4: Update Info.plist for Privacy

1. **Add Privacy Descriptions**
   - The project uses `GENERATE_INFOPLIST_FILE = YES`, so we need to add privacy keys
   - Create or update: `B2 Berufssprachkurs/Info.plist` (if it doesn't exist, create it)
   - Or add these keys in Xcode: **Target → Info → Custom iOS Target Properties**

2. **Required Privacy Keys**
   Add these keys to Info.plist:
   
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-1380989901130305~8662057835</string>
   
   <key>SKAdNetworkItems</key>
   <array>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>cstr6suwn9.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>4fzdc2evr5.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>4pfyvq9l8r.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>2fnua5tdw4.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>ydx93a7ass.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>5a6flpkh64.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>p78axxw29g.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>v72qych5uu.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>ludvb6z3bs.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>cp8zw746q7.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>3sh42y64q3.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>c6k4g5qg8m.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>s39g8k73mm.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>3qy4746246.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>f38h382jlk.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>hs6bdukanm.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>prcb7njmu6.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>v4nxqhlyqp.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>wzmmz9fp6w.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>yclnxrl5pm.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>t38b2kh725.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>7ug5zh24hu.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>gta9lk7p23.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>vutu7akeur.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>y5ghdn5j9q.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>n6fk4nfna4.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>v9wttpbfk9.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>n38lu8286q.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>47vhws6wlr.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>kbd757ywx3.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>9t245vhmpl.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>eh6m2bh4zr.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>a2p9lx4jpn.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>22mmun2rn5.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>4468km3ulz.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>2u9pt9hc89.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>8s468mfl3y.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>klf5c3l5u5.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>ppxm28t8ap.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>ecpz2srf59.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>uw77j35x4d.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>pwa83g58rt.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>mlmmfzh3r3.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>578prtvx9j.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>4dzt52r2t5.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>e5fvkxwrpn.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>8c4e2ghe7u.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>zq492l623r.skadnetwork</string>
       </dict>
       <dict>
           <key>SKAdNetworkIdentifier</key>
           <string>3qcr597p9d.skadnetwork</string>
       </dict>
   </array>
   
   <key>NSUserTrackingUsageDescription</key>
   <string>This allows us to show you relevant ads and support the free version of the app.</string>
   ```

   **Note:** The SKAdNetworkItems list should be updated with the latest list from Google. Check: https://developers.google.com/admob/ios/ios14#skadnetworkids

---

## Step 5: Create AdManager Service

1. **Create AdManager Service File**
   - Create: `B2 Berufssprachkurs/01 - Services/AdManager.swift`

2. **Implement AdManager**
   This service will handle ad initialization and management:
   
   ```swift
   import Foundation
   import GoogleMobileAds
   
   @MainActor
   class AdManager: ObservableObject {
       static let shared = AdManager()
       
       @Published var isInitialized = false
       @Published var canShowInterstitial = false
       
       private var interstitialAd: GADInterstitialAd?
       
       private init() {}
       
       func initialize() {
           guard !isInitialized else { return }
           
           GADMobileAds.sharedInstance().start(completionHandler: { [weak self] status in
               Task { @MainActor in
                   self?.isInitialized = true
                   print("AdMob initialized with status: \(status.adapterStatusesByClassName)")
               }
           })
           
           // Preload interstitial ad
           loadInterstitialAd()
       }
       
       func loadInterstitialAd() {
           let request = GADRequest()
           GADInterstitialAd.load(withAdUnitID: AdMobConfig.currentInterstitialAdUnitID,
                                  request: request) { [weak self] ad, error in
               Task { @MainActor in
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
           
           ad.present(fromRootViewController: viewController)
           canShowInterstitial = false
           interstitialAd = nil
           
           // Preload next ad
           loadInterstitialAd()
       }
   }
   
   extension AdManager: GADFullScreenContentDelegate {
       func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
           print("Ad dismissed")
           loadInterstitialAd()
       }
       
       func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
           print("Ad failed to present: \(error.localizedDescription)")
           loadInterstitialAd()
       }
   }
   ```

---

## Step 6: Create SwiftUI Ad Wrapper Views

1. **Create Banner Ad View**
   - Create: `B2 Berufssprachkurs/02 - Components/BannerAdView.swift`
   
   ```swift
   import SwiftUI
   import GoogleMobileAds
   import UIKit
   
   struct BannerAdView: UIViewRepresentable {
       let adUnitID: String
       
       func makeUIView(context: Context) -> GADBannerView {
           let banner = GADBannerView(adSize: GADAdSizeBanner)
           banner.adUnitID = adUnitID
           banner.rootViewController = UIApplication.shared.windows.first?.rootViewController
           
           let request = GADRequest()
           banner.load(request)
           
           return banner
       }
       
       func updateUIView(_ uiView: GADBannerView, context: Context) {
           // No updates needed
       }
   }
   
   // SwiftUI wrapper for easy use
   struct BannerAd: View {
       var body: some View {
           BannerAdView(adUnitID: AdMobConfig.currentBannerAdUnitID)
               .frame(height: 50)
               .frame(maxWidth: .infinity)
       }
   }
   ```

2. **Create Interstitial Ad Helper**
   - Create: `B2 Berufssprachkurs/02 - Components/InterstitialAdHelper.swift`
   
   ```swift
   import SwiftUI
   import UIKit
   
   struct InterstitialAdHelper {
       static func showInterstitialAd() {
           guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                 let rootViewController = windowScene.windows.first?.rootViewController else {
               return
           }
           
           AdManager.shared.showInterstitialAd(from: rootViewController)
       }
   }
   ```

---

## Step 7: Integrate Ads into Views

1. **Initialize AdMob in App Delegate**
   - Update: `B2 Berufssprachkurs/00 - Core/B2_BerufssprachkursApp.swift`
   
   Add to `AppDelegate` class:
   ```swift
   func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
       // Initialize AdMob
       AdManager.shared.initialize()
       return true
   }
   ```

2. **Add Banner Ad to HomeView**
   - Update: `B2 Berufssprachkurs/08 - Views/01 - Home/HomeView.swift`
   
   Add banner ad at the bottom of the view:
   ```swift
   BannerAd()
       .padding(.bottom, 8)
   ```

3. **Show Interstitial Ads at Strategic Points**
   - After completing a study session
   - When switching between major sections
   - After viewing a certain number of words
   
   Example usage:
   ```swift
   Button("Complete Session") {
       // Your completion logic
       InterstitialAdHelper.showInterstitialAd()
   }
   ```

---

## Step 8: Implement App Tracking Transparency

1. **Add AppTrackingTransparency Framework**
   - In Xcode: **Target → General → Frameworks, Libraries, and Embedded Content**
   - Click "+" and add `AppTrackingTransparency.framework`

2. **Create Tracking Manager**
   - Create: `B2 Berufssprachkurs/01 - Services/TrackingManager.swift`
   
   ```swift
   import AppTrackingTransparency
   import AdSupport
   
   class TrackingManager {
       static func requestTrackingPermission() {
           DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               ATTrackingManager.requestTrackingAuthorization { status in
                   switch status {
                   case .authorized:
                       print("Tracking authorized")
                   case .denied:
                       print("Tracking denied")
                   case .notDetermined:
                       print("Tracking not determined")
                   case .restricted:
                       print("Tracking restricted")
                   @unknown default:
                       print("Unknown tracking status")
                   }
               }
           }
       }
   }
   ```

3. **Request Permission in App**
   - Update: `B2 Berufssprachkurs/00 - Core/B2_BerufssprachkursApp.swift`
   
   Add to `AppDelegate.didFinishLaunchingWithOptions`:
   ```swift
   TrackingManager.requestTrackingPermission()
   ```

---

## Step 9: Testing with Test Ads

1. **Use Test Ad Unit IDs**
   - The `AdMobConfig` already includes test ad unit IDs
   - In DEBUG mode, test ads are used automatically

2. **Test on Simulator and Device**
   - Run the app in DEBUG mode
   - Verify test ads appear correctly
   - Test banner, interstitial, and rewarded ads

3. **Verify Ad Placement**
   - Check that ads don't interfere with UI
   - Ensure ads are properly sized
   - Test in both Light and Dark modes

---

## Step 10: Best Practices & Guidelines

### Ad Placement Guidelines

1. **Banner Ads**
   - Place at bottom of content screens
   - Don't place on every screen (avoid ad fatigue)
   - Good locations: HomeView, WordsListView

2. **Interstitial Ads**
   - Show after completing study sessions
   - Limit frequency (e.g., every 3-5 sessions)
   - Don't interrupt critical user flows

3. **Rewarded Ads (Optional)**
   - Offer rewards for watching ads
   - Example: "Watch ad to unlock premium features for 1 hour"

### User Experience

1. **Respect User Privacy**
   - Always request tracking permission
   - Provide clear explanation in privacy policy

2. **Don't Overwhelm Users**
   - Limit ad frequency
   - Ensure ads don't block important content

3. **Test Thoroughly**
   - Test on multiple devices
   - Test in different network conditions
   - Verify ads work in both Light and Dark modes

### App Store Guidelines

1. **Privacy Policy**
   - Update privacy policy to mention AdMob
   - Include information about data collection

2. **App Store Connect**
   - Declare use of AdMob in App Privacy section
   - Answer questions about ad networks

3. **Content Guidelines**
   - Ensure ads comply with App Store guidelines
   - Monitor ad content (use AdMob's content filtering)

---

## Troubleshooting

### Common Issues

1. **Ads Not Showing**
   - Check Ad Unit IDs are correct
   - Verify App ID in Info.plist
   - Check network connection
   - Ensure using test ads in DEBUG mode

2. **Build Errors**
   - Verify GoogleMobileAds package is added
   - Clean build folder (Cmd+Shift+K)
   - Rebuild project

3. **Privacy Warnings**
   - Ensure NSUserTrackingUsageDescription is set
   - Verify SKAdNetworkItems are included

---

## Next Steps After Integration

1. **Test Thoroughly**
   - Test all ad types
   - Verify on physical devices
   - Test in different scenarios

2. **Monitor Performance**
   - Check AdMob dashboard for impressions
   - Monitor revenue
   - Adjust ad placement based on performance

3. **Update Documentation**
   - Update CHANGELOG.md
   - Update RELEASE_NOTES_1.0.1.md
   - Update APP_STORE_SUBMISSION.md

4. **Submit to App Store**
   - Ensure all privacy information is complete
   - Test with TestFlight
   - Submit for review

---

## Additional Resources

- [Google AdMob iOS Documentation](https://developers.google.com/admob/ios)
- [AdMob Best Practices](https://support.google.com/admob/answer/6329638)
- [App Tracking Transparency](https://developer.apple.com/documentation/apptrackingtransparency)
- [SKAdNetwork IDs](https://developers.google.com/admob/ios/ios14#skadnetworkids)

---

## Checklist

- [x] Created Google AdMob account
- [x] Added app to AdMob dashboard
- [ ] Created ad units (Banner, Interstitial, Rewarded)
- [ ] Added GoogleMobileAds SDK via SPM
- [ ] Created AdMobConfig.swift with App ID and Ad Unit IDs
- [ ] Updated Info.plist with GADApplicationIdentifier
- [ ] Added SKAdNetworkItems to Info.plist
- [ ] Added NSUserTrackingUsageDescription
- [ ] Created AdManager service
- [ ] Created BannerAdView component
- [ ] Created InterstitialAdHelper
- [ ] Initialized AdMob in AppDelegate
- [ ] Integrated banner ads into views
- [ ] Implemented App Tracking Transparency
- [ ] Tested with test ads
- [ ] Updated privacy policy
- [ ] Updated App Store Connect privacy information
- [ ] Tested on physical devices
- [ ] Updated CHANGELOG.md
- [ ] Updated RELEASE_NOTES_1.0.1.md

---

**Note:** Replace all placeholder Ad Unit IDs and App IDs with your actual values from the AdMob dashboard before building for production.

