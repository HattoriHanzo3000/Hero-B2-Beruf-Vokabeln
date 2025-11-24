# App Store Submission Checklist - B2 Berufssprachkurs

## Version Information
- **Marketing Version**: 1.0
- **Build Number**: 1
- **Bundle ID**: com.gizatech.B2-Berufssprachkurs
- **Development Team**: SZQ626NP5U

## App Information

### App Name
B2 Berufssprachkurs

### Description
A comprehensive German vocabulary learning app designed for B2 level students preparing for the telc B2 Berufssprachkurs exam. Features interactive flashcards, spaced repetition, and vocabulary practice with translations, explanations, synonyms, and example sentences.

### Key Features
- **Word of the Day**: Daily vocabulary with customizable sections
- **Flashcard Study System**: Practice with translations, explanations, synonyms, and examples
- **Verbs with Prepositions**: Dedicated section for German verbs with prepositions and cases
- **Spaced Repetition**: Intelligent review system for optimal learning
- **Bilingual Support**: English and German interface
- **Accessibility**: Full VoiceOver support, Dynamic Type, and haptic feedback
- **Customizable**: Appearance (Light/Dark/System), text size, and language preferences

## Technical Details

### Supported Languages
- English (en)
- German (de)

### Supported Devices
- iPhone
- iPad

### Minimum iOS Version
iOS 18.1

### App Store Categories
- Education
- Reference

## Pre-Submission Checklist

### Code & Build
- [x] All code committed to repository
- [x] Version number set (1.0)
- [x] Build number set (1)
- [x] Bundle identifier configured
- [x] Code signing configured
- [ ] Archive build created in Xcode
- [ ] Build validated in App Store Connect

### Assets Required
- [ ] App Icon (1024x1024px)
- [ ] Screenshots for all device sizes:
  - [ ] iPhone 6.7" (iPhone 14 Pro Max, iPhone 15 Pro Max)
  - [ ] iPhone 6.5" (iPhone 11 Pro Max, iPhone XS Max)
  - [ ] iPhone 5.5" (iPhone 8 Plus)
  - [ ] iPad Pro 12.9" (3rd generation)
  - [ ] iPad Pro 12.9" (2nd generation)
- [ ] App Preview Video (optional but recommended)
- [ ] Privacy Policy URL (if required)

### App Store Connect Setup
- [ ] App created in App Store Connect
- [ ] App information completed:
  - [ ] Name
  - [ ] Subtitle
  - [ ] Description
  - [ ] Keywords
  - [ ] Support URL (REQUIRED)
  - [ ] Marketing URL (optional but recommended)
  - [ ] Privacy Policy URL (REQUIRED if app collects data)
- [ ] Pricing and availability set
- [ ] App Store listing screenshots uploaded
- [ ] App preview video uploaded (if applicable)
- [ ] Version information completed
- [ ] Build selected and submitted for review

### Content & Localization
- [x] English localization complete
- [x] German localization complete
- [x] All UI strings localized
- [x] App Store description prepared (English)
- [ ] App Store description prepared (German)

### Privacy & Compliance
- [ ] Privacy Policy prepared and hosted
- [ ] Privacy Policy URL added to App Store Connect
- [ ] App Privacy details completed in App Store Connect
- [ ] Age rating questionnaire completed

### URLs Required for App Store Connect

**Support URL (REQUIRED):**
- Must be a valid, publicly accessible URL
- Should contain contact information, FAQ, or support resources
- Example: `https://www.gizatech.de/support` or `https://www.gizatech.de/contact`
- Can be a simple page with email contact: `info@gizatech.de`
- **Current email from app:** `info@gizatech.de`

**Marketing URL (OPTIONAL but recommended):**
- Website promoting your app
- Landing page with app features, screenshots, benefits
- Can be same as support URL if you don't have a separate marketing site
- Example: `https://www.gizatech.de/hero-deutsch-b2-beruf`
- **If you don't have a website:** You can use the support URL or create a simple landing page

**Privacy Policy URL (REQUIRED if app collects user data):**
- Must be a valid, publicly accessible URL
- Required if app collects any user data (even if just analytics)
- Should explain what data is collected and how it's used
- Example: `https://www.gizatech.de/privacy-policy`
- **Note:** Even if app doesn't collect data, Apple recommends having a privacy policy

**Quick Setup Options:**

1. **If you have a website:**
   - Support URL: `https://www.gizatech.de/support` or `/contact`
   - Marketing URL: `https://www.gizatech.de/hero-deutsch-b2-beruf` or `/apps`
   - Privacy Policy: `https://www.gizatech.de/privacy-policy`

2. **If you don't have a website yet:**
   - Create a simple GitHub Pages site, or
   - Use a free hosting service (GitHub Pages, Netlify, etc.), or
   - Use a simple contact form service
   - Support URL: Can be a simple page with email: `info@gizatech.de`
   - Marketing URL: Can be same as support URL or omitted
   - Privacy Policy: Create a simple page explaining no data collection

**Minimum Required:**
- Support URL: Must provide a way for users to contact you (email or contact form)
- Privacy Policy URL: Required for App Store submission

### Testing
- [ ] Tested on physical devices (iPhone and iPad)
- [ ] Tested in both Light and Dark modes
- [ ] Tested with different text sizes
- [ ] Tested language switching
- [ ] Tested all study modes
- [ ] Verified accessibility features
- [ ] Tested on different iOS versions (if applicable)

## Recent Changes (v1.0)

### UI/UX Improvements
- Refactored action header bar - moved Üben buttons to header position
- Implemented liquid glass tab bar with transparent background
- Added check-all button to scrollable lists
- Improved button interaction (two-tap system: select then activate)
- Enhanced localization support

### Features
- Word of the Day with customizable sections
- Flashcard study system with multiple modes
- Verbs with prepositions section
- Spaced repetition algorithm
- Bilingual interface (English/German)

### Technical
- iOS 18.1+ support
- SwiftUI-based architecture
- MVVM pattern
- Combine framework for reactive programming
- Full accessibility support

## Next Steps

1. **Create Archive Build**
   - Open project in Xcode
   - Select "Any iOS Device" as destination
   - Product > Archive
   - Wait for archive to complete

2. **Validate Archive**
   - In Organizer window, select archive
   - Click "Validate App"
   - Fix any issues found

3. **Upload to App Store Connect**
   - In Organizer, select validated archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Follow distribution wizard

4. **Complete App Store Connect**
   - Add app screenshots
   - Complete app description
   - Set pricing
   - Submit for review

## Notes
- Ensure all test accounts are removed before submission
- Review App Store Review Guidelines
- Check for any deprecated APIs
- Verify all external links work
- Test app with TestFlight before submission

