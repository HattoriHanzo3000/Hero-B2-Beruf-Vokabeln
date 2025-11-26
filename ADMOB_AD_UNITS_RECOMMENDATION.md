# AdMob Ad Units Recommendation for Hero - Deutsch B2 Beruf

Based on your app structure and user experience considerations, here are my recommendations for the 6 ad units:

## Recommended Ad Units (Priority Order)

### 1. **Banner Ad** (Home Screen) ⭐ HIGHEST PRIORITY
**Ad Unit Type:** Banner  
**Placement:** Bottom of `HomeView`  
**Why:**
- Non-intrusive, always visible
- Doesn't interrupt learning flow
- Good for consistent revenue
- Users can ignore it while studying

**Implementation:**
```swift
// In HomeView.swift - at the bottom of VStack
BannerAd()
    .padding(.bottom, 8)
```

---

### 2. **Interstitial Ad** (After Study Sessions) ⭐ HIGHEST PRIORITY
**Ad Unit Type:** Interstitial  
**Placement:** After completing a study session in `StudyView`  
**Why:**
- Natural break point (user just finished studying)
- High engagement (user is taking a break anyway)
- Good revenue potential
- Doesn't interrupt active learning

**Implementation:**
```swift
// In StudyView.swift - when user dismisses or completes session
.onDisappear {
    // Show ad every 2-3 completed sessions
    if shouldShowInterstitial() {
        InterstitialAdHelper.showInterstitialAd()
    }
}
```

**Frequency:** Show every 2-3 completed study sessions (not every time)

---

### 3. **Rewarded Ad** (Premium Features) ⭐ HIGH PRIORITY
**Ad Unit Type:** Rewarded  
**Placement:** Offer to unlock premium features temporarily  
**Why:**
- Users choose to watch (better UX)
- Can offer value: "Watch ad to unlock all sections for 1 hour"
- Higher eCPM than regular ads
- Users feel in control

**Use Cases:**
- Unlock all sections for 1 hour
- Remove ads for 1 hour
- Access premium study modes temporarily
- Unlock additional practice sessions

**Implementation:**
```swift
// Add a button in SettingsView or HomeView
Button("Watch Ad to Unlock Premium Features") {
    showRewardedAd()
}
```

---

### 4. **Banner Ad** (Words List Screen) ⭐ MEDIUM PRIORITY
**Ad Unit Type:** Banner  
**Placement:** Bottom of `WordsListView`  
**Why:**
- Additional revenue stream
- Users browsing word lists (less focused than studying)
- Can be dismissed by scrolling

**Implementation:**
```swift
// In WordsListView.swift - at the bottom
BannerAd()
    .padding(.bottom, 8)
```

---

### 5. **Interstitial Ad** (Tab Switching) ⭐ MEDIUM PRIORITY
**Ad Unit Type:** Interstitial  
**Placement:** When switching between major tabs (Words/Verbs/Settings)  
**Why:**
- Natural transition point
- User is changing context anyway
- Good for occasional revenue

**Frequency:** Show every 5-7 tab switches (very infrequent)

**Implementation:**
```swift
// In MainTabView.swift
.onChange(of: selectedTab) { oldValue, newValue in
    tabSwitchCount += 1
    if tabSwitchCount % 7 == 0 {
        InterstitialAdHelper.showInterstitialAd()
    }
}
```

---

### 6. **Native Ad** (Word List Integration) ⭐ OPTIONAL
**Ad Unit Type:** Native  
**Placement:** Within word lists (blends with content)  
**Why:**
- Less intrusive than banners
- Blends with app design
- Good for users who find banners distracting
- Higher engagement when done well

**Alternative:** If you don't want native ads, use this slot for:
- **App Open Ad** (when app launches) - but this can be too aggressive for learning apps
- **Second Rewarded Ad Unit** (for different rewards)

---

## My Top 3 Recommendations

If you want to start simple, focus on these 3:

1. **Banner Ad (Home)** - Always visible, non-intrusive
2. **Interstitial Ad (After Study)** - Natural break point, high value
3. **Rewarded Ad (Premium Features)** - User choice, high eCPM

## Ad Unit Naming Convention

When creating in AdMob dashboard, use clear names:

1. `Home Banner Ad`
2. `Study Session Interstitial`
3. `Premium Rewarded Ad`
4. `Words List Banner Ad`
5. `Tab Switch Interstitial`
6. `Native Word List Ad` (or `App Open Ad`)

## Revenue Potential Ranking

1. **Interstitial Ad (After Study)** - Highest revenue
2. **Rewarded Ad** - High revenue, user choice
3. **Banner Ad (Home)** - Consistent, steady revenue
4. **Banner Ad (Words List)** - Additional revenue
5. **Interstitial Ad (Tab Switch)** - Occasional revenue
6. **Native Ad** - Variable, depends on implementation

## User Experience Considerations

### ✅ DO:
- Show ads at natural break points
- Limit interstitial frequency (every 2-3 sessions, not every time)
- Offer value with rewarded ads
- Keep banners non-intrusive
- Test ad placement thoroughly

### ❌ DON'T:
- Show ads during active studying
- Overwhelm users with too many ads
- Show interstitials too frequently
- Block important UI elements
- Show ads immediately on app launch (let user start learning first)

## Implementation Priority

**Phase 1 (Start Here):**
1. Banner Ad (Home)
2. Interstitial Ad (After Study)
3. Rewarded Ad (Premium)

**Phase 2 (Add Later):**
4. Banner Ad (Words List)
5. Interstitial Ad (Tab Switch)
6. Native Ad or App Open Ad

## Testing Strategy

1. Start with test ads in DEBUG mode
2. Test on physical device (not just simulator)
3. Verify ads don't break UI in Light/Dark modes
4. Test with different screen sizes
5. Monitor user feedback after release
6. Adjust frequency based on user behavior

---

## Quick Decision Guide

**If you want maximum revenue:**
- Use all 6 units, but be careful with frequency

**If you want best user experience:**
- Use 3 units: Banner (Home), Interstitial (After Study), Rewarded

**If you want to test first:**
- Start with Banner (Home) and Interstitial (After Study)
- Add Rewarded Ad after seeing user response

---

**Recommendation:** Start with the top 3 (Banner Home, Interstitial After Study, Rewarded), then add the others based on user feedback and revenue data.

