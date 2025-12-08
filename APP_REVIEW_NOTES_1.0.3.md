# Additional Information for Apple App Review - Version 1.0.3

## App Review Notes for App Store Connect

**Copy and paste this into the "Additional Information" field in App Store Connect:**

---

### App Overview
Hero - Deutsch B2 Beruf is an educational vocabulary learning app for German B2 level. The app helps users learn and practice German vocabulary through interactive flashcards, spaced repetition, and multiple study modes. All content is stored locally on the device - no internet connection required for core features. The app now includes an optional premium subscription for enhanced features.

### Testing Instructions

**Getting Started:**
1. Launch the app - you'll see a beautiful launch screen with the Hero mascot on first launch
2. After the launch screen, you'll see a welcome video (first time only)
3. After the video, you'll see the main interface with three tabs: Words, Verbs, and Settings
4. No login or account creation required - the app works immediately

**Key Features to Test:**

**1. Premium Subscription (NEW in 1.0.3):**
- Navigate to Settings tab
- Tap on "Premium" section (if available) or look for premium-related options
- The app offers a 3-day free trial for new users
- Premium subscription unlocks ad-free experience and full feature access
- Subscription can be purchased through standard StoreKit purchase flow
- Subscription is auto-renewable and can be managed in App Store settings
- Test subscription purchase: Use sandbox test account credentials when prompted
- Note: The app is fully functional without subscription - core features remain free

**2. Progress Statistics (NEW in 1.0.3):**
- Navigate to Settings → Statistics (or Progress)
- View beautiful ring charts showing learning progress
- Statistics include: mastered, reinforced, familiar, and words to study
- See overall readiness percentage for exam preparation
- Statistics update in real-time as you study

**3. PDF Export (NEW in 1.0.3):**
- Navigate to any word list (e.g., Words tab → Lektion 1 → 1A)
- Look for PDF export/share button (usually in header or toolbar)
- Tap to generate PDF of the current word list
- PDF includes words, translations, examples, and explanations
- Professional two-column layout suitable for printing
- Can be shared via standard iOS share sheet

**4. Word of the Day (Header Section):**
- Located at the top of the "Words" tab
- Displays a random German word with explanation, synonyms, and translation
- Tap the mascot (eagle) to see animation
- Can be customized in Settings → Word of the Day

**5. Study Modes:**
- Navigate to any word section (e.g., tap "Lektion 1" → tap "1A")
- You'll see three practice buttons at the top:
  - "Mit Übersetzung üben" (Practice with Translation)
  - "Mit Erklärung üben" (Practice with Explanation)  
  - "Mit Synonym üben" (Practice with Synonym)
- Tap a button TWICE to start studying:
  - First tap: Expands the button (visual feedback)
  - Second tap: Starts the flashcard study session

**6. Verbs with Prepositions:**
- Go to the "Verbs" tab (second tab)
- You'll see a list of prepositions (an, auf, aus, bei, etc.)
- Tap any preposition to see verbs with that preposition
- Two study modes available:
  - "Mit Übersetzung üben" (Practice with Translation)
  - "Mit Beispiel üben" (Practice with Example) - shows sentences with prepositions

**7. Flashcard Study:**
- After selecting a study mode, you'll see flashcards
- Tap card to flip and see the answer
- Swipe right for "Know it", left for "Study more"
- Progress is saved locally on device
- Progress statistics update automatically

**8. Settings:**
- Third tab contains all app settings
- Language: Switch between English and German interface
- Appearance: Light/Dark/System mode
- Text Size: Adjustable font sizes
- Word of the Day: Enable/disable and select sections
- Statistics: View progress and learning statistics
- Premium: Access subscription management
- All settings work immediately without restart

**9. Check All Feature:**
- In any word list, you'll see "Alle auswählen" (Select All) button at the top left
- Tap to mark all words in that section as completed
- Useful for testing the "Study All" mode

**10. Launch Screen (NEW in 1.0.3):**
- Beautiful launch screen appears before welcome video
- Features the Hero mascot
- Brief, professional introduction to the app

### App-Specific Settings

**For Subscription Testing:**
- Use sandbox tester account created in App Store Connect
- Test the full subscription purchase flow
- Test subscription restoration (if implemented)
- Verify subscription status updates correctly
- Test trial period activation

**No special settings required for core features:**
- The app works out of the box with default settings
- All content is included in the app bundle (no downloads needed)
- No user accounts, login, or registration required
- Core features work without subscription

**Optional Settings to Test:**
- Language switching: Settings → App Language → Switch between English/Deutsch
- Word of the Day customization: Settings → Word of the Day → Select sections
- Appearance modes: Settings → Appearance → Test Light/Dark modes
- Statistics view: Settings → Statistics → View progress charts

### Content Information

**Vocabulary Content:**
- Over 1,800 German words total
- Regular vocabulary words across multiple chapters (chapters 1-12)
- 174 verbs with prepositions across 17 sections
- Adjectives organized by preposition
- All words include: German word, translation, explanation, synonyms, and example sentences
- Content is educational and appropriate for B2 level German learners
- All content stored locally in app bundle

**New Content in 1.0.3:**
- Chapters 4-12 added with comprehensive vocabulary
- Enhanced content organization
- Improved loading performance

**Data Storage:**
- All data stored locally on device using UserDefaults
- User progress (checked words, translations, statistics) saved locally
- No cloud sync or external servers for core functionality
- Subscription status managed by StoreKit (Apple's system)

### Subscription Details

**Premium Subscription:**
- Product ID: `monthly_1.99_3d_trial`
- Pricing: $1.99/month (or equivalent in local currency)
- 3-day free trial for new users
- Auto-renewable subscription
- Cancellable anytime in App Store settings

**Premium Features:**
- Ad-free experience
- Full access to all features
- Priority features as they're added

**Subscription Testing:**
- Use sandbox environment for testing
- Test purchase, cancellation, and renewal flows
- Verify subscription status updates correctly
- Test free trial activation

### Testing Checklist

**Please verify:**
- [ ] App launches without crashes
- [ ] Launch screen displays correctly on first launch
- [ ] Welcome video plays on first launch
- [ ] All three tabs (Words, Verbs, Settings) are accessible
- [ ] Word of the Day displays correctly
- [ ] Can navigate to word sections and view words
- [ ] Study modes work (Translation, Explanation, Synonym, Example)
- [ ] Flashcards flip correctly and respond to swipes
- [ ] Progress statistics update correctly
- [ ] PDF export generates and shares correctly
- [ ] Premium subscription purchase flow works
- [ ] Subscription status displays correctly
- [ ] Settings can be changed and persist
- [ ] Language switching works (English ↔ Deutsch)
- [ ] App works in both Light and Dark modes
- [ ] Text size adjustments work
- [ ] "Select All" feature works
- [ ] Core features work without subscription
- [ ] No internet connection required for core features (works offline)

### Known Behaviors

**Expected App Behavior:**
- First launch shows launch screen, then welcome video (can be skipped)
- Word of the Day updates daily (based on 24-hour periodicity setting)
- Study progress is saved automatically
- Statistics update in real-time
- App remembers last selected study mode
- Tab bar is hidden during study sessions (by design)
- Premium subscription is optional - core features remain free
- Subscription purchase requires internet connection (handled by StoreKit)

**Accessibility:**
- Full VoiceOver support
- Dynamic Type support (adjustable text sizes)
- Haptic feedback on button interactions
- High contrast support in Dark mode
- All premium features accessible via VoiceOver

### Technical Notes

**Platform Requirements:**
- iOS 18.1 or later
- iPhone only (iPad support removed)
- Portrait orientation only (locked via AppDelegate)
- StoreKit 2 for subscription management

**Performance:**
- All content loads instantly (bundled in app)
- Smooth animations and transitions
- Optimized for all iPhone sizes
- No network requests for core features (fully offline)
- StoreKit handles subscription-related network requests

**Privacy:**
- No user data collection beyond standard App Store analytics
- Subscription information managed by Apple/StoreKit
- All user progress stored locally on device
- No external analytics or tracking

### Contact Information

If you have any questions during review, please contact:
- Email: info@gizatech.de
- Support URL: https://www.gizatech.de/hero-b2-beruf

---

## Additional Notes for Reviewer

**Privacy:**
- This app does NOT collect personal user data
- No analytics, tracking, or user identification
- All learning data stored locally on device
- Subscription information handled by Apple's StoreKit
- Privacy Policy available at: https://www.gizatech.de/hero-b2-beruf/privacy-policy

**Content:**
- All vocabulary content is educational and appropriate
- Content is static (bundled in app, not downloaded)
- No user-generated content
- No social features or sharing
- Content appropriate for B2 level German learners

**Subscription Compliance:**
- Follows Apple's Subscription Guidelines
- Clear pricing displayed before purchase
- 3-day free trial as advertised
- Auto-renewable subscription with clear terms
- Standard StoreKit implementation
- Subscription can be managed in App Store settings
- Core features remain free (subscription is optional)

**Functionality:**
- App is fully functional without internet connection (core features)
- Subscription purchase requires internet (handled by StoreKit)
- No server-side components for core functionality
- No user authentication required
- All core features accessible immediately
- Premium features unlock additional functionality

**Testing Tips:**
- The app is intuitive - no special knowledge needed to test
- All features are accessible from the main interface
- Try different study modes to see variety
- Test language switching to see bilingual interface
- Check Settings to see customization options
- Test subscription with sandbox account
- Verify core features work without subscription
- Test PDF export and sharing functionality
- Check progress statistics as you study

**Subscription Testing Notes:**
- Use sandbox tester account for subscription testing
- Subscription purchases in sandbox are free for testing
- Test the full purchase flow including free trial
- Verify subscription status updates correctly
- Test app behavior with active subscription
- Test app behavior without subscription (core features should work)

Thank you for reviewing our app!

