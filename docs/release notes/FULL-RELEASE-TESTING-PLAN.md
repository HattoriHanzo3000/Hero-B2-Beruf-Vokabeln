# B2 Berufssprachkurs: Full Release Testing Plan
This plan is designed to ensure the app meets "Editors’ Choice" standards. Follow these steps sequentially to verify functionality, performance, and Apple’s Human Interface Guidelines (HIG).

---

## 🛠 Preparation
*   **Use a Real Device:** Testing on an iPhone is mandatory for haptics, battery, and thermal performance.
*   **Network Link Conditioner:** (Optional) If you have a Mac, use this to simulate "3G" or "High Latency" to see how the app handles slow loads.
*   **Fresh Start:** Delete any existing version of the app before starting Phase 1.

---

## Phase 1: First Impressions (Installation & Onboarding)
*Goal: Ensure the very first 30 seconds of the app feel premium and stable.*

- [ ] **Cold Launch Performance:** Open the app for the first time.
    - *Check:* Does the UI appear instantly? 
    - *Check:* Does the `MascotView` load without stuttering?
    - *Check:* verify the `HeroFreeTrialChip` does **not** flicker (it should use the local cache we implemented).
- [ ] **Onboarding Flow:** If you have an onboarding sequence, go through it slowly.
    - *Check:* Are there any layout breaks on smaller screens (iPhone SE) or larger screens (iPhone 16 Pro Max)?
- [ ] **Permission Requests:** Trigger notifications or other permissions.
    - *Check:* Is the "Purpose String" (the text explaining why you need the permission) clear and friendly?

---

## Phase 2: Core Learning Experience (Functional Testing)
*Goal: Verify the main "Job to be Done" works perfectly.*

- [ ] **Word of the Day (WOTD):**
    - *Action:* Change the `wordOfTheDayPeriodicity` in Settings.
    - *Check:* Does the `HeaderView` update the word immediately?
    - *Check:* Tap the Mascot. Does the GIF play and then return to the static image correctly?
- [ ] **Content Navigation:**
    - *Action:* Navigate deep into a lesson and then swipe back from the left edge of the screen.
    - *Check:* Is the "Interactive Pop Gesture" smooth?
- [ ] **Data Persistence:**
    - *Action:* Complete a task or mark a word as "learned."
    - *Check:* Force-close the app and reopen it. Is your progress still there?
- [ ] **Search & Filters:** (If applicable)
    - *Check:* Does the search feel "live" and responsive?

---

## Phase 3: Visuals & "The Apple Polish" (UI/UX)
*Goal: Match Apple’s editorial design values (clarity, elegance, resonance).*

- [ ] **Dark Mode Transitions:**
    - *Action:* While on the Home screen, toggle Dark Mode in Control Center.
    - *Check:* Do the gradients in `pinnedHeaderGradientBackground` transition smoothly?
    - *Check:* Does the Mascot switch between "Mascot" and "MascotDark" correctly?
- [ ] **Accessibility: Dynamic Type:**
    - *Action:* Go to Settings > Accessibility > Display & Text Size > Larger Text. Set it to maximum.
    - *Check:* Does the `HeaderView` handle the text without overlapping?
- [ ] **Accessibility: Reduce Motion:**
    - *Action:* Turn on "Reduce Motion" in iOS Settings.
    - *Check:* Does the Mascot GIF stop auto-playing?
- [ ] **Haptic Feedback:**
    - *Check:* Do buttons and successful actions provide a subtle "tap" (haptic)?

---

## Phase 4: Monetization & Paywall (StoreKit/RevenueCat)
*Goal: Ensure zero friction in the "Pro" upgrade path.*

- [ ] **Paywall Presentation:**
    - *Action:* Tap the `HeroFreeTrialChip`.
    - *Check:* Does the paywall slide up smoothly? 
    - *Check:* Is the "Close" button easy to reach?
- [ ] **Purchasing Flow (Sandbox):**
    - *Action:* Complete a purchase with a sandbox account.
    - *Check:* Does the app immediately show the "PRO" badge without needing a restart?
- [ ] **Restore Purchases:**
    - *Action:* Tap "Restore Purchases."
    - *Check:* Does a success or "Not Found" message appear clearly?
- [ ] **Offline Cache:**
    - *Action:* Turn on Airplane Mode and launch the app.
    - *Check:* Does `lastKnownPremiumState` correctly remember your "Pro" status?

---

## Phase 5: Reliability & Edge Cases (Technical QA)
*Goal: The "Unbreakable App" check.*

- [ ] **Background/Foregrounding:**
    - *Action:* Be in the middle of a lesson → Home Screen → Open 3 other apps → Return to Hero.
    - *Check:* Did the app stay on the same screen?
- [ ] **No Internet State:**
    - *Action:* Launch the app without Wi-Fi or Cellular.
    - *Check:* Does it show a friendly "Check Connection" message instead of an empty white screen?
- [ ] **Widget Sync:** (If using Widgets)
    - *Check:* Does the `WordOfTheDayView` in the widget match the word shown inside the app?

---

## Phase 6: Final Polish Checklist
- [ ] **Localization:** Switch device to German and then English. No "missing keys" (e.g., `HERO_LABEL_123`) should be visible.
- [ ] **App Icon:** Does it look good against different wallpapers (Light/Dark/Tinted)?
- [ ] **Privacy Policy:** Does the link in Settings actually open a webpage?

---

### ✅ Success Criteria for Submission
If you can check off every item above, your app is in the **Top 5%** of submission quality. You are ready to upload to App Store Connect!
