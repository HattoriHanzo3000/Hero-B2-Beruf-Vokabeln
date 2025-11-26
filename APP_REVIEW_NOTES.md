# Additional Information for Apple App Review

## App Review Notes for App Store Connect

**Copy and paste this into the "Additional Information" field in App Store Connect:**

---

### App Overview
Hero - Deutsch B2 Beruf is an educational vocabulary learning app for German B2 level. The app helps users learn and practice German vocabulary through interactive flashcards, spaced repetition, and multiple study modes. All content is stored locally on the device - no internet connection or user accounts required.

### Testing Instructions

**Getting Started:**
1. Launch the app - you'll see a welcome video on first launch
2. After the video, you'll see the main interface with three tabs: Words, Verbs, and Settings
3. No login or account creation required - the app works immediately

**Key Features to Test:**

**1. Word of the Day (Header Section):**
- Located at the top of the "Words" tab
- Displays a random German word with explanation, synonyms, and translation
- Tap the mascot (eagle) to see animation
- Can be customized in Settings → Word of the Day

**2. Study Modes:**
- Navigate to any word section (e.g., tap "Lektion 1" → tap "1A")
- You'll see three practice buttons at the top:
  - "Mit Übersetzung üben" (Practice with Translation)
  - "Mit Erklärung üben" (Practice with Explanation)  
  - "Mit Synonym üben" (Practice with Synonym)
- Tap a button TWICE to start studying:
  - First tap: Expands the button (visual feedback)
  - Second tap: Starts the flashcard study session

**3. Verbs with Prepositions:**
- Go to the "Verbs" tab (second tab)
- You'll see a list of prepositions (an, auf, aus, bei, etc.)
- Tap any preposition to see verbs with that preposition
- Two study modes available:
  - "Mit Übersetzung üben" (Practice with Translation)
  - "Mit Beispiel üben" (Practice with Example) - shows sentences with prepositions

**4. Flashcard Study:**
- After selecting a study mode, you'll see flashcards
- Tap card to flip and see the answer
- Swipe right for "Know it", left for "Study more"
- Progress is saved locally on device

**5. Settings:**
- Third tab contains all app settings
- Language: Switch between English and German interface
- Appearance: Light/Dark/System mode
- Text Size: Adjustable font sizes
- Word of the Day: Enable/disable and select sections
- All settings work immediately without restart

**6. Check All Feature:**
- In any word list, you'll see "Alle auswählen" (Select All) button at the top left
- Tap to mark all words in that section as completed
- Useful for testing the "Study All" mode

### App-Specific Settings

**No special settings required for testing:**
- The app works out of the box with default settings
- All content is included in the app bundle (no downloads needed)
- No user accounts, login, or registration required
- No in-app purchases or subscriptions

**Optional Settings to Test:**
- Language switching: Settings → App Language → Switch between English/Deutsch
- Word of the Day customization: Settings → Word of the Day → Select sections
- Appearance modes: Settings → Appearance → Test Light/Dark modes

### Content Information

**Vocabulary Content:**
- 1,806 German words total
- 1,632 regular vocabulary words across 60 sections
- 174 verbs with prepositions across 17 sections
- All words include: German word, translation, explanation, synonyms, and example sentences
- Content is educational and appropriate for B2 level German learners

**Data Storage:**
- All data stored locally on device using UserDefaults and Core Data
- No cloud sync or external servers
- User progress (checked words, translations) saved locally
- No personal data collection or transmission

### Testing Checklist

**Please verify:**
- [ ] App launches without crashes
- [ ] Welcome video plays on first launch
- [ ] All three tabs (Words, Verbs, Settings) are accessible
- [ ] Word of the Day displays correctly
- [ ] Can navigate to word sections and view words
- [ ] Study modes work (Translation, Explanation, Synonym, Example)
- [ ] Flashcards flip correctly and respond to swipes
- [ ] Settings can be changed and persist
- [ ] Language switching works (English ↔ Deutsch)
- [ ] App works in both Light and Dark modes
- [ ] Text size adjustments work
- [ ] "Select All" feature works
- [ ] No internet connection required (works offline)

### Known Behaviors

**Expected App Behavior:**
- First launch shows welcome video (can be skipped by swiping)
- Word of the Day updates daily (based on 24-hour periodicity setting)
- Study progress is saved automatically
- App remembers last selected study mode
- Tab bar is hidden during study sessions (by design)

**Accessibility:**
- Full VoiceOver support
- Dynamic Type support (adjustable text sizes)
- Haptic feedback on button interactions
- High contrast support in Dark mode

### Technical Notes

**Platform Requirements:**
- iOS 18.1 or later
- iPhone only (iPad support removed)
- Portrait orientation only (locked via AppDelegate)
- No external dependencies or frameworks

**Performance:**
- All content loads instantly (bundled in app)
- Smooth animations and transitions
- Optimized for all iPhone sizes
- No network requests (fully offline)

### Contact Information

If you have any questions during review, please contact:
- Email: info@gizatech.de
- Support URL: [Your support URL]

---

## Additional Notes for Reviewer

**Privacy:**
- This app does NOT collect any user data
- No analytics, tracking, or user identification
- All data stored locally on device
- Privacy Policy available at: [Your privacy policy URL]

**Content:**
- All vocabulary content is educational and appropriate
- Content is static (bundled in app, not downloaded)
- No user-generated content
- No social features or sharing

**Functionality:**
- App is fully functional without internet connection
- No server-side components
- No user authentication required
- All features accessible immediately

**Testing Tips:**
- The app is intuitive - no special knowledge needed to test
- All features are accessible from the main interface
- Try different study modes to see variety
- Test language switching to see bilingual interface
- Check Settings to see customization options

Thank you for reviewing our app!


