# AdMob Implementation Examples

This file shows concrete examples of how to integrate AdMob into your existing views.

## 1. Initialize AdMob in App Delegate

Update `B2 Berufssprachkurs/00 - Core/B2_BerufssprachkursApp.swift`:

```swift
// AppDelegate to handle orientation
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize AdMob
        AdManager.shared.initialize()
        
        // Request tracking permission (after a short delay)
        TrackingManager.requestTrackingPermission()
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
```

## 2. Add Banner Ad to HomeView

Update `B2 Berufssprachkurs/08 - Views/01 - Home/HomeView.swift`:

```swift
struct HomeView: View {
    // ... existing code ...
    
    var body: some View {
        ZStack {
            Color("AppGreenLight")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                HeaderView(dataService: dataService)
                
                // Üben button group
                UbenButtonGroup(
                    selectedButtonType: $selectedButtonType,
                    onButtonTap: { buttonType in
                        navigateToStudy = true
                    }
                )
                
                // Lections list
                LectionsListView(dataService: dataService)
                    .frame(maxHeight: .infinity)
                    .padding(.top, 12)
                
                // Banner Ad at the bottom
                BannerAd()
                    .padding(.bottom, 8)
            }
        }
        // ... rest of existing code ...
    }
}
```

## 3. Show Interstitial Ad After Study Session

Update `B2 Berufssprachkurs/08 - Views/03 - Flash Cards/StudyView.swift`:

Add this when a study session is completed:

```swift
// In your completion handler or button action
Button("Complete Session") {
    // Your existing completion logic
    // ...
    
    // Show interstitial ad after session
    InterstitialAdHelper.showInterstitialAd()
}
```

Or track session count and show ad every N sessions:

```swift
@AppStorage("studySessionCount") private var studySessionCount = 0

func completeStudySession() {
    // Your existing logic
    studySessionCount += 1
    
    // Show ad every 3 sessions
    if studySessionCount % 3 == 0 {
        InterstitialAdHelper.showInterstitialAd()
    }
}
```

## 4. Add Banner Ad to WordsListView (Optional)

If you want to add a banner ad to the words list view:

```swift
// In WordsListView.swift
VStack {
    // Your existing content
    List {
        // ... words list ...
    }
    
    // Banner ad at bottom
    BannerAd()
        .padding(.bottom, 8)
}
```

## 5. Show Interstitial When Switching Tabs (Optional)

You can show interstitial ads when users switch between major sections:

```swift
// In MainTabView.swift
struct MainTabView: View {
    @State private var selectedTab: TabItem = .words
    @State private var tabChangeCount = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ... your tabs ...
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            tabChangeCount += 1
            
            // Show ad every 5 tab switches
            if tabChangeCount % 5 == 0 {
                InterstitialAdHelper.showInterstitialAd()
            }
        }
    }
}
```

## 6. Conditional Ad Display (Premium Users)

If you plan to have premium users, you can conditionally show ads:

```swift
@AppStorage("isPremiumUser") private var isPremiumUser = false

var body: some View {
    VStack {
        // Your content
        
        // Only show ad if not premium
        if !isPremiumUser {
            BannerAd()
                .padding(.bottom, 8)
        }
    }
}
```

## 7. Update Info.plist

Since your project uses `GENERATE_INFOPLIST_FILE = YES`, you need to add the Info.plist keys manually:

1. In Xcode, select your target
2. Go to **Info** tab
3. Click **+** to add new keys
4. Add these keys:

**GADApplicationIdentifier** (String)
- Value: `ca-app-pub-1380989901130305~8662057835`

**NSUserTrackingUsageDescription** (String)
- Value: `This allows us to show you relevant ads and support the free version of the app.`

**SKAdNetworkItems** (Array)
- Add all the SKAdNetworkIdentifier dictionaries as shown in the main guide

Alternatively, create a `Info.plist` file in your project root and add it to the target.

## 8. Add AppTrackingTransparency Framework

1. In Xcode: **Target → General → Frameworks, Libraries, and Embedded Content**
2. Click **+**
3. Search for `AppTrackingTransparency`
4. Add it

## Testing Checklist

- [ ] Test banner ads appear correctly
- [ ] Test interstitial ads show at appropriate times
- [ ] Verify ads work in Light mode
- [ ] Verify ads work in Dark mode
- [ ] Test on physical device (not just simulator)
- [ ] Verify tracking permission dialog appears
- [ ] Test with test ad unit IDs (DEBUG mode)
- [ ] Verify ads don't block important UI elements
- [ ] Test ad loading in poor network conditions

## Notes

- Always use test ads during development
- Replace placeholder Ad Unit IDs with real ones before production
- Monitor AdMob dashboard for performance
- Consider user experience - don't overwhelm with ads
- Follow Apple's App Store guidelines for ad placement

