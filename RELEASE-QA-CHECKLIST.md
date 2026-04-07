# Release QA Checklist (iOS)

Use this checklist before submitting to the App Store.

## How to run tests
- Run app from Xcode on a real iPhone
- Keep Xcode Console open during tests
- Mark each item when completed

---

## 1) Basic open/close stability

- [ ] Open app
- [ ] Close app fully (swipe away from app switcher)
- [ ] Open app again
- [ ] Repeat full close/open 5 times
- [ ] Confirm no crash, no freeze, no strange flash

---

## 2) Main navigation (all tabs)

- [ ] Home tab opens
- [ ] Cockpit tab opens
- [ ] Search tab opens
- [ ] Settings tab opens
- [ ] Open at least one screen from each tab
- [ ] Go back from each screen successfully
- [ ] Confirm no blank screens

---

## 3) Learning flows

- [ ] Open a word list
- [ ] Tap several words
- [ ] Edit a translation
- [ ] Save and verify translation is kept
- [ ] Add a word to favorites
- [ ] Remove a word from favorites
- [ ] Open Study / Flashcards
- [ ] Swipe left/right and flip cards
- [ ] Leave and re-open Study successfully

---

## 4) My Words flow

- [ ] Open My Words
- [ ] Add a new word
- [ ] Edit that word
- [ ] Delete that word
- [ ] Close app fully and reopen
- [ ] Confirm My Words data persists correctly

---

## 5) Subscription and paywall

- [ ] Open paywall
- [ ] Close paywall
- [ ] Open paywall again
- [ ] Tap Restore Purchase
- [ ] Confirm feedback message appears
- [ ] Open Your Plan screen
- [ ] Confirm plan status is correct
- [ ] Close app fully and reopen
- [ ] Confirm app does not downgrade unexpectedly
- [ ] Confirm locked Pro features stay correct

---

## 6) Settings + localization + appearance

- [ ] Change app language to English
- [ ] Change app language to Deutsch
- [ ] Confirm key texts update correctly
- [ ] Set appearance to Light
- [ ] Set appearance to Dark
- [ ] Set appearance to System
- [ ] Open FAQ link
- [ ] Open Terms link
- [ ] Open Privacy link

---

## 7) Offline / reconnect behavior

- [ ] Turn Airplane mode ON
- [ ] Open app and switch tabs
- [ ] Open key screens (Home, Settings, Paywall)
- [ ] Confirm app does not crash
- [ ] Turn Airplane mode OFF
- [ ] Confirm app recovers normally

---

## 8) Accessibility quick check

- [ ] Increase text size (larger accessibility size) and re-check key screens
- [ ] Confirm no clipped/overlapping text
- [ ] (Optional) Turn on VoiceOver and check key buttons are understandable

---

## 9) Performance quick check

- [ ] App launch feels smooth
- [ ] Tab switching is smooth
- [ ] No major UI stutters in Study/Home/Settings

---

## 10) Final release gate (must pass)

- [ ] No crash found in this test run
- [ ] No data-loss issue found
- [ ] Subscription state stable after relaunch
- [ ] Core flows work (Home, Study, My Words, Settings, Paywall)
- [ ] Ready for Archive + App Store submission

---

## Console notes (Xcode)

### Usually safe to ignore
- [ ] Benign Apple framework warnings that do not affect behavior

### Must investigate before release
- [ ] `Fatal error`
- [ ] `Terminating app due to uncaught exception`
- [ ] Repeating entitlement/purchase errors
- [ ] Any log followed by UI break or freeze

---

## Test result summary

- Device model: __________________
- iOS version: __________________
- Build/version tested: __________________
- Date: __________________
- Tester: __________________

### Issues found
- [ ] None
- [ ] Yes (list below)

1. __________________
2. __________________
3. __________________

### Decision
- [ ] Ready to submit
- [ ] Fix required before submit
