//
//  Localizable.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import Foundation

enum Localizable {
    static func string(_ key: String, tableName: String = "Localizable") -> String {
        let bundle = LanguageManager.shared.localizedBundle()
        return NSLocalizedString(key, tableName: tableName, bundle: bundle, value: key, comment: "")
    }
}

// Localization keys
extension Localizable {
    // Existing
    static let practiseWithSynonyms = "practise_with_synonyms"
    static let practiseWithTranslations = "practise_with_translations"
    static let practiseWithExplanation = "practise_with_explanation"
    static let practiseWithSynonym = "practise_with_synonym"
    static let practiseWithTranslation = "practise_with_translation"
    static let selectAll = "select_all"
    
    // Tab Bar
    static let home = "home"
    static let words = "words"
    static let verbs = "verbs"
    
    // Practice buttons
    static let practiseWithExample = "practise_with_example"
    
    // Study view
    static let cards = "cards"
    static let study = "study"
    static let synonym = "synonym"
    static let explanation = "explanation"
    static let translation = "translation"
    static let addTranslationToWord = "add_translation_to_word"
    
    // Check all button
    static let allSelected = "all_selected"
    
    // Settings
    static let settings = "settings"
    static let about = "about"
    static let update = "update"
    static let premium = "premium"
    static let wordOfTheDay = "word_of_the_day"
    static let periodicity = "periodicity"
    static let sourceSections = "source_sections"
    static let allSections = "all_sections"
    static let selectedSections = "selected_sections"
    static let appLanguage = "app_language"
    static let english = "english"
    static let deutsch = "deutsch"
    static let hapticFeedback = "haptic_feedback"
    static let appearance = "appearance"
    static let light = "light"
    static let dark = "dark"
    static let system = "system"
    static let displayAndTextSize = "display_and_text_size"
    static let extraSmall = "extra_small"
    static let small = "small"
    static let medium = "medium"
    static let large = "large"
    static let extraLarge = "extra_large"
    static let xxLarge = "xx_large"
    static let xxxLarge = "xxx_large"
    static let faq = "faq"
    static let faqDescription = "faq_description"
    static let contactUs = "contact_us"
    static let sendEmail = "send_email"
    static let contactUsEmailSubject = "contact_us_email_subject"
    static let contactUsEmailBody = "contact_us_email_body"
    static let mailUnavailable = "mail_unavailable"
    static let mailUnavailableMessage = "mail_unavailable_message"
    static let ok = "ok"
    static let reportABug = "report_a_bug"
    static let impressum = "impressum"
    static let termsOfUse = "terms_of_use"
    static let privacyPolicy = "privacy_policy"
    static let resetApp = "reset_app"
    static let resetAppTitle = "reset_app_title"
    static let resetAppMessage = "reset_app_message"
    static let reset = "reset"
    static let cancel = "cancel"

    static let iCloudSync = "icloud_sync"
    static let iCloudSyncFooter = "icloud_sync_footer"
    static let iCloudAccountSignedIn = "icloud_account_signed_in"
    static let iCloudAccountNotSignedIn = "icloud_account_not_signed_in"
    
    // About page
    static let aboutThisApp = "about_this_app"
    static let aboutAppDescription = "about_app_description"
    static let deviceInformation = "device_information"
    static let name = "name"
    static let version = "version"
    static let model = "model"
    static let systemVersion = "system_version"
    static let appVersion = "app_version"
    
    // Periodicity
    static let hours12 = "12_hours"
    static let hours24 = "24_hours"
    static let hours12Short = "12_hours_short"
    static let hours24Short = "24_hours_short"
    
    // Update page
    static let currentVersion = "current_version"
    static let updateAvailable = "update_available"
    static let versionUpdates = "version_updates"
    static let versionUpdatesPlaceholder = "version_updates_placeholder"
    static let newVersionAvailable = "new_version_available"
    static let thisUpdateAdds = "this_update_adds"
    static let updateNow = "update_now"
    static let updateButtonHint = "update_button_hint"
    static let updateAlertTitle = "update_alert_title"
    static let updateAlertMessage = "update_alert_message"
    static let remindMeLater = "remind_me_later"
    
    // Cockpit / Sections
    static let verbsWithPrepositions = "verbs_with_prepositions"
    
    // Cockpit
    static let progress = "progress"
    static let progressSubtitle = "progress_subtitle"
    static let cockpitWotdIntro = "cockpit_wotd_intro"
    static let wordOfTheDayDescription = "word_of_the_day_description"
    static let progressDescription = "progress_description"
    static let progressUnderConstruction = "progress_under_construction"
    static let progressComingSoon = "progress_coming_soon"
    
    // Statistics
    static let statisticsWrongTitle = "statistics_wrong_title"
    static let statisticsFamiliarTitle = "statistics_familiar_title"
    static let statisticsReinforcedTitle = "statistics_reinforced_title"
    static let statisticsMasteredTitle = "statistics_mastered_title"
    static let statisticsWrongDescription = "statistics_wrong_description"
    static let statisticsFamiliarDescription = "statistics_familiar_description"
    static let statisticsReinforcedDescription = "statistics_reinforced_description"
    static let statisticsMasteredDescription = "statistics_mastered_description"
    
    // Home Cards
    static let generalWords = "general_words"
    static let adjectivesWithPrepositions = "adjectives_with_prepositions"
    static let favorites = "favorites"
    static let favoritesWordsTitle = "favorites_words_title"
    
    // Practice button
    static let practice = "practice"
    
    // Header Greeting
    static let greetingWordOfTheDay = "greeting_word_of_the_day"
    static let greetingWordOfTheDay1 = "greeting_word_of_the_day_1"
    static let greetingWordOfTheDay2 = "greeting_word_of_the_day_2"
    static let greetingWordOfTheDay3 = "greeting_word_of_the_day_3"
    static let greetingWordOfTheDay4 = "greeting_word_of_the_day_4"
    static let greetingWordOfTheDay5 = "greeting_word_of_the_day_5"
    
    // Premium
    static let proBenefitsDescription = "pro_benefits_description"
    static let unlockHeroPremium = "unlock_hero_premium"
    static let premiumPromoSubtitle = "premium_promo_subtitle"
    static let paywallTitleFutureGermany = "paywall_title_future_germany"
    static let enjoyHeroPremium = "enjoy_hero_premium"
    static let enjoyFullHeroExperience = "enjoy_full_hero_experience"
    static let premiumActiveSubtitle = "premium_active_subtitle"
    static let getPremiumFeaturesBack = "get_premium_features_back"
    static let premiumFeaturesBackSubtitle = "premium_features_back_subtitle"
    static let monthlySubscription = "monthly_subscription"
    static let perMonth = "per_month"
    static let month = "month"
    static let monthly = "monthly"
    static let yearly = "yearly"
    static let lifetime = "lifetime"
    static let monthlyExplanation = "monthly_explanation"
    static let yearlyExplanation = "yearly_explanation"
    static let lifetimeExplanation = "lifetime_explanation"
    static let lifetimeExplanationLine2 = "lifetime_explanation_line2"
    static let freeTrial = "free_trial"
    static let iCloudFamilySharing = "icloud_family_sharing"
    static let restorePurchase = "restore_purchase"
    static let upgradeToPremium = "upgrade_to_premium"
    static let premiumMonthly = "premium_monthly"
    static let premium3Months = "premium_3_months"
    static let premiumYearly = "premium_yearly"
    static let months3 = "months_3"
    static let year1 = "year_1"
    static let basic = "basic"
    static let benefits = "benefits"
    static let free = "free"
    static let premiumColumn = "premium_column"
    static let noAds = "no_ads"
    static let subscribeNow = "subscribe_now"
    static let unlockPremium = "unlock_premium"
    static let startFreeTrial = "start_free_trial"
    static let changePlan = "change_plan"
    static let continueButton = "continue_button"
    static let subscriptionTerms = "subscription_terms"
    static let subscriptionTermsMonthly = "subscription_terms_monthly"
    static let subscriptionTermsQuarterly = "subscription_terms_quarterly"
    static let subscriptionTermsYearly = "subscription_terms_yearly"
    static let subscriptionTermsLifetime = "subscription_terms_lifetime"
    static let subscriptionTitle = "subscription_title"
    static let subscriptionLength = "subscription_length"
    static let quarterlyExplanation = "quarterly_explanation"
    static let paywallBestValue = "paywall_best_value"
    
    // Launch offer (3-day lifetime promo)
    static let launchOfferBadge = "launch_offer_badge"
    static let launchOfferExpiresIn = "launch_offer_expires_in"
    
    // Promo Code
    static let promoCode = "promo_code"
    static let enterPromoCode = "enter_promo_code"
    static let redeem = "redeem"
    static let redeemSpecialOffer = "redeem_special_offer"
    static let code = "code"
    static let promoCodePremiumActive = "promo_code_premium_active"
    static let promoCodeFooter = "promo_code_footer"
    
    // Study Empty State
    static let noWordsSelected = "no_words_selected"
    static let noWordsSelectedMessage = "no_words_selected_message"
    static let translationNotFound = "translation_not_found"
    static let translationNotFoundMessage = "translation_not_found_message"
    
    // Favorites Empty State
    static let noFavoritesFound = "no_favorites_found"
    static let noFavoritesFoundMessage = "no_favorites_found_message"
    
    // Premium Lock
    static let premiumRequired = "premium_required"
    static let unlockPremiumToUseFeature = "unlock_premium_to_use_feature"
    
    // Rating Prompt
    static let ratingTitle = "rating_title"
    static let ratingSubtitle = "rating_subtitle"
    static let ratingRateButton = "rating_rate_button"
    static let ratingLaterButton = "rating_later_button"
    static let ratingNoThanksButton = "rating_no_thanks_button"
    
    // Share
    static let share = "share"
    static let scanQRCode = "scan_qr_code"
    static let scanToDownload = "scan_to_download"
    static let openInAppStore = "open_in_app_store"
    
    // Holiday Seasonal Banner
    static let holidaySeasonSale = "holiday_season_sale"
    static let holidaySeasonSaleDescription = "holiday_season_sale_description"
    static let holidaySeasonSaleDescriptionNoPrice = "holiday_season_sale_description_no_price"
    static let regularPrice = "regular_price"
    static let sale = "sale"
    
    // Subscription Terms - Promotional
    static let subscriptionTermsYearlyPromotional = "subscription_terms_yearly_promotional"
}

