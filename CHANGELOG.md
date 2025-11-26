# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

