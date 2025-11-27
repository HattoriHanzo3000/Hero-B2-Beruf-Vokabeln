# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 27.11.2025

### Added
- Adjectives with prepositions section (14th section) to Word of the Day selection
- AdjectivesListView component for better organization
- PremiumView for future premium features
- PromoCodeManager service for promo code handling

### Changed
- Updated checkmark colors to system primary color across all word categories (General Words, Verbs, Adjectives)
- Standardized checkmark sizes and styles for consistency
- Improved translation update mechanism in DataService with proper change notifications
- Enhanced study view to only load words with available content (translation/synonym/explanation) for adjectives

### Fixed
- Fixed adjectives cards not loading translations in study view
- Fixed study view including empty adjective cards when only examples were available
- Improved translation synchronization when adding or editing translations
- Fixed translation updates not triggering study view refresh

### Technical Updates
- Enhanced DataService.updateTranslation() to properly trigger @Published change notifications
- Improved study view logic to match adjectives behavior with other word categories
- Better state management for translation updates

## [1.0.1] - 26.11.2025

### Added
- Google AdMob integration with banner, interstitial, and rewarded ads
- AdManager service for centralized ad management
- TrackingManager for user tracking consent handling
- App Tracking Transparency support
- Comprehensive AdMob integration documentation
- Firebase hosting setup for app-ads.txt
- SKAdNetwork items configuration for ad attribution

### Changed
- Improved project structure with file system synchronized groups
- Enhanced build configuration with explicit settings for AppIntents
- Info.plist moved to project root to prevent Copy Bundle Resources warning

### Fixed
- Resolved Swift 6 concurrency warnings in AdManager
- Fixed Info.plist Copy Bundle Resources build phase warning
- Improved thread safety in ad loading callbacks with proper weak self captures
- Fixed build configuration warnings for cleaner compilation

### Technical Updates
- Updated build settings to exclude Info.plist from resource copying
- Added proper concurrency handling with MainActor isolation
- Optimized ad loading with proper delegate handling

## [1.0] - 25.11.2025

### Initial Release
- First version submitted to App Store
- Word of the Day with customizable sections
- Flashcard study system with multiple modes
- Verbs with prepositions section
- Spaced repetition algorithm
- Bilingual interface (English/German)
- Full accessibility support (VoiceOver, Dynamic Type, haptic feedback)
- Light/Dark/System appearance modes
- iOS 18.1+ support

