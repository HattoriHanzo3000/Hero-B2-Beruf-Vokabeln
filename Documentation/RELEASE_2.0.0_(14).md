# Hero B2 - Internal Release Notes

## Version 2.0 (Build 14)

Release date: 2026-04-14  
Baseline tag: `1.0.8(13)`  
Audience: Internal only

---

## What's New (Internal - English)

### 1) Core Learning Experience

- Added global vocabulary search with clearer result context and smoother section behavior.
- Improved Study and Flashcards interaction flow and responsiveness.
- Expanded synonym support across custom words and study-related UI.
- Improved keyboard navigation and typing flow in translation input components.

### 2) My Words, Favorites, and Personal Progress

- Added swipe-to-delete in My Words, including animated delete interactions.
- Improved Favorites interaction polish with clearer deletion feedback.
- Upgraded persistence by integrating SwiftData migration from UserDefaults for key learning data.
- Improved reliability of vocabulary state and progress handling.

### 3) Subscription, Paywall, and Pro Experience

- Reworked Paywall and Your Plan experience across multiple iterations.
- Improved subscription restore flow and user feedback messaging.
- Prevented Pro status flashing and improved entitlement stability on app launch.
- Added stable RevenueCat user ID persistence and improved cold-start subscription safety.
- Consolidated product identifier handling across StoreKit and RevenueCat integration.
- Completed terminology transition from Premium to Pro for consistency.

### 4) Widgets and Ecosystem Integrations

- Added and refactored Hero widgets (Word of the Day, quick actions, lock-screen support).
- Added widget-side data sync and persistence through app group support.
- Updated widget localization resources and visual assets.

### 5) UX, Visual Design, and Motion

- Refined UI across Home, Cockpit, My Words, Global Search, Settings, and list screens.
- Updated Hero visual assets and added GIF-based mascot animation support.
- Improved typography consistency in synonyms and explanatory text areas.
- Improved color system consistency with learning-surface palette refinements.
- Added celebratory feedback effects in selected premium and settings flows.

### 6) Localization and Accessibility

- Expanded and cleaned up EN/DE localization keys across major screens.
- Replaced hardcoded labels with localized strings in detail and support surfaces.
- Improved accessibility labels and hints in favorites-related components.
- Added localization verification as part of release QA.

### 7) Export, Sharing, and Utility

- Improved PDF generation quality, localization, footer/page formatting, and error handling.
- Improved share/export flows for words and study content.
- Added sorting and print-related utility improvements in learning collections.

### 8) Architecture, Code Health, and Reliability

- Performed broad refactoring across services and views for maintainability.
- Standardized code comment and documentation header quality in many files.
- Removed deprecated or unused components and old monetization integrations.
- Improved app lifecycle initialization and service wiring reliability.

---

## What's New (External - English)

### 1) Learning and Practice

- Smoother flashcards and study flow for a more focused learning rhythm.
- Improved vocabulary search, so finding the right word is faster and easier.
- Better support for synonyms to make practice feel richer and more natural.
- Cleaner typing and keyboard interactions while working with translations.

### 2) My Words and Favorites

- Easier word management in My Words, including faster delete actions.
- More polished interactions in Favorites with clearer visual feedback.
- Improved stability of your saved words and learning progress.

### 3) Pro Experience

- Upgraded Pro and plan screens for a clearer and more confident upgrade journey.
- Improved purchase restore flow with better in-app feedback.
- More reliable Pro status behavior after app launch.

### 4) Widgets and Everyday Access

- Improved widgets experience for Word of the Day and quick actions.
- Better consistency between app content and widget content.

### 5) Design and Feel

- Refined interface across Home, Cockpit, Settings, and list screens.
- Better typography and visual hierarchy for improved readability.
- Smoother motion and richer feedback in key moments.

### 6) Language and Accessibility

- Improved English and German text quality across important screens.
- Better clarity of labels and messages throughout the app.
- Accessibility improvements for clearer navigation and understanding.

### 7) Share and Export

- Improved export and sharing experience for learning content.
- More consistent output quality and formatting.

### 8) Stability and Reliability

- Better overall stability during everyday use.
- Performance and reliability improvements across key user flows.

## Was ist neu (Extern - Deutsch)

### 1) Lernen und Ueben

- Fluessigerer Lern- und Karteikartenfluss fuer konzentrierteres Ueben.
- Verbesserte Vokabelsuche, damit du Woerter schneller und einfacher findest.
- Bessere Synonym-Unterstuetzung fuer abwechslungsreicheres Lernen.
- Klarere Tastatur- und Eingabeinteraktionen bei Uebersetzungen.

### 2) Meine Woerter und Favoriten

- Einfachere Verwaltung in Meine Woerter, inklusive schnellerer Loeschaktionen.
- Verfeinerte Interaktionen in Favoriten mit klarerem visuellem Feedback.
- Mehr Stabilitaet bei gespeicherten Woertern und deinem Lernfortschritt.

### 3) Pro-Erlebnis

- Ueberarbeitete Pro- und Tarifansichten fuer ein klareres Upgrade-Erlebnis.
- Verbesserte Wiederherstellung von Kaeufen mit verstaendlicherem Feedback.
- Zuverlaessigeres Pro-Verhalten direkt nach dem App-Start.

### 4) Widgets und schneller Zugriff

- Verbesserte Widgets fuer Wort des Tages und Schnellaktionen.
- Hoehere Uebereinstimmung zwischen App-Inhalten und Widget-Inhalten.

### 5) Design und App-Gefuehl

- Verfeinerte Oberflaeche in Home, Cockpit, Einstellungen und Listenansichten.
- Bessere Typografie und visuelle Hierarchie fuer leichtere Lesbarkeit.
- Ruhigere Animationen und hochwertigeres Feedback in wichtigen Momenten.

### 6) Sprache und Barrierefreiheit

- Verbesserte Textqualitaet in Deutsch und Englisch auf zentralen Screens.
- Klarere Beschriftungen und Hinweise in der gesamten App.
- Verbesserungen bei der Barrierefreiheit fuer bessere Orientierung.

### 7) Teilen und Export

- Verbesserter Export- und Share-Flow fuer Lerninhalte.
- Konsistentere Ausgabequalitaet und Formatierung.

### 8) Stabilitaet und Zuverlaessigkeit

- Insgesamt stabilere App im taeglichen Einsatz.
- Weitere Performance- und Zuverlaessigkeitsverbesserungen in wichtigen Ablaufen.

---

## Apple Tester Notes (App Review)

Use this block when submitting the build in App Store Connect ("Notes for Review").

### 1) Test Scope and Goal

- Primary goal: verify the core learning flow (Home -> word lists -> Study/Flashcards -> My Words/Favorites -> Settings).
- Secondary goal: verify Pro purchase, restore, and locked/unlocked state behavior.
- Platforms in scope: iPhone. (Add iPad here if this build includes tablet-specific review scope.)

### 2) How to Access Key Features

- App opens directly to the main tab navigation. No login is required for core learning features.
- Free flows can be tested immediately in Home, Search, Study, and Settings.
- Pro flows are reachable from the in-app paywall entry points in Home/Settings.

### 3) Subscription / In-App Purchase Testing

- Product type: auto-renewable subscription.
- Restore flow location: Paywall -> Restore Purchases.
- Expected result after restore: Pro state is applied without requiring app reinstall.

### 4) Important Behaviors to Validate

- App remains stable after force close and relaunch.
- Saved words and favorites persist after relaunch.
- Localization can be switched and key screens render correctly in English and German.
- Widget content (if tested) should match in-app Word of the Day.

### 5) Network and Device Notes

- App should work under normal network conditions; offline mode should not cause crashes.


---

## Quality and Release Operations

- Added an internal release QA checklist and full release testing plan.
- Added app-ads declaration support documentation.
- Updated app display name to `Hero B2`.
- Updated project marketing version to `2.0` and build number to `14`.

## Breaking/Behavioral Changes to Watch

- Persistence layer migration to SwiftData may affect legacy user-state edge cases.
- Subscription and entitlement logic changed significantly; monitor restore and state transitions.
- Widget architecture changed substantially; validate sync and timeline behavior on device.

## Recommended Smoke Test Focus (Post-release)

1. Launch and cold-start stability, including Pro state consistency.
2. My Words add/edit/delete flow and persistence after force close.
3. Search performance and result quality.
4. Study/flashcard flow, gestures, and keyboard behavior.
5. Widget parity with in-app Word of the Day.
6. PDF export and share flow in both English and German.

## Source Traceability

Primary comparison range:

- `git log --oneline 1.0.8(13)..HEAD`
- `git diff --name-only 1.0.8(13)..HEAD`
