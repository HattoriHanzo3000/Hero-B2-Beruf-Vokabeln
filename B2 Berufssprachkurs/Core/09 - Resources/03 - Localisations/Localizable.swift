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
    static let tabSearchAccessibility = "tab_search_accessibility"

    // Global vocabulary search
    static let searchVocabularyTitle = "search_vocabulary_title"
    static let searchVocabularyPrompt = "search_vocabulary_prompt"
    /// Short row badge in search results (Verben mit Präpositionen)
    static let searchBadgeVerbs = "search_badge_verbs"
    /// Short row badge in search results (Adjektive mit Präpositionen)
    static let searchBadgeAdjectives = "search_badge_adjectives"
    /// Short row badge in search results (My Words)
    static let searchBadgeMyWords = "search_badge_my_words"
    
    // Practice buttons
    static let practiseWithExample = "practise_with_example"
    
    // Study view
    static let card = "card"
    static let cards = "cards"
    static let study = "study"
    static let synonym = "synonym"
    /// Plural label (e.g. study mode).
    static let synonyms = "synonyms"
    static let explanation = "explanation"
    static let translation = "translation"
    static let auto = "auto"
    static let clearTranslationInput = "clear_translation_input"
    static let clearTranslationInputHint = "clear_translation_input_hint"
    static let addTranslationToWord = "add_translation_to_word"

    // Words list (section word list + rows)
    static let wordsListA11yLabel = "words_list_a11y_label"
    static let wordsListA11yHint = "words_list_a11y_hint"
    static let wordRowFavoriteAddA11y = "word_row_favorite_add_a11y"
    static let wordRowFavoriteRemoveA11y = "word_row_favorite_remove_a11y"
    static let wordRowFavoriteValueFavoritedA11y = "word_row_favorite_value_favorited_a11y"
    static let wordRowFavoriteValueNotFavoritedA11y = "word_row_favorite_value_not_favorited_a11y"
    /// Format: German lemma (VoiceOver hint for star).
    static let wordRowFavoriteHintFormat = "word_row_favorite_hint_format"
    static let wordRowTranslationOpenKeyboardHintA11y = "word_row_translation_open_keyboard_hint_a11y"
    /// Format: translation text.
    static let wordRowTranslationDisplayA11y = "word_row_translation_display_a11y"
    static let wordRowTranslationEditHintA11y = "word_row_translation_edit_hint_a11y"
    static let wordRowDetailExplanationA11y = "word_row_detail_explanation_a11y"
    static let wordRowDetailExampleA11y = "word_row_detail_example_a11y"
    static let wordRowDetailSynonymsA11y = "word_row_detail_synonyms_a11y"
    /// Inline list row / PDF prefix: `abbr.: ` (period before colon; shared so UI and export stay aligned).
    static let wordRowDetailLabelExplanation = "word_row_detail_label_explanation"
    static let wordRowDetailLabelExample = "word_row_detail_label_example"
    static let wordRowDetailLabelSynonyms = "word_row_detail_label_synonyms"
    /// Word-of-the-day header: same `abbr.: ` style as other row labels.
    static let wordRowDetailLabelTranslation = "word_row_detail_label_translation"

    /// PDF running footer: current page and total page count (two integers).
    static let pdfPageOfTotalFormat = "pdf_page_of_total_format"

    /// Translation field keyboard accessory (prev / next / done).
    static let keyboardNavPreviousWordA11y = "keyboard_nav_previous_word_a11y"
    static let keyboardNavPreviousWordHintA11y = "keyboard_nav_previous_word_hint_a11y"
    static let keyboardNavNextWordA11y = "keyboard_nav_next_word_a11y"
    static let keyboardNavNextWordHintA11y = "keyboard_nav_next_word_hint_a11y"
    static let keyboardNavDoneHintA11y = "keyboard_nav_done_hint_a11y"

    /// Favorites list (VoiceOver).
    static let favoritesListA11yLabel = "favorites_list_a11y_label"
    static let favoritesListA11yHint = "favorites_list_a11y_hint"
    /// Format: German lemma.
    static let wordRowA11ySummaryEditing = "word_row_a11y_summary_editing"
    /// Format: German lemma, localized “add translation” phrase.
    static let wordRowA11ySummaryPromptTranslation = "word_row_a11y_summary_prompt_translation"
    /// Format: German lemma, translation text.
    static let wordRowA11ySummaryWithTranslation = "word_row_a11y_summary_with_translation"
    /// Format: German lemma.
    static let wordRowContainerA11y = "word_row_container_a11y"

    static let flashcardNoTranslationYet = "flashcard_no_translation_yet"
    static let flashcardNoExplanationYet = "flashcard_no_explanation_yet"
    static let flashcardNoSynonymYet = "flashcard_no_synonym_yet"

    /// VoiceOver: flashcard index in session (format: two integers).
    static let studyFlashcardPositionA11y = "study_flashcard_position_a11y"
    static let studyFlashcardHintA11y = "study_flashcard_hint_a11y"
    static let studyMarkWrongA11y = "study_mark_wrong_a11y"
    static let studyMarkWrongHintA11y = "study_mark_wrong_hint_a11y"
    static let studyMarkCorrectA11y = "study_mark_correct_a11y"
    static let studyMarkCorrectHintA11y = "study_mark_correct_hint_a11y"
    static let studyFavoriteRemoveA11y = "study_favorite_remove_a11y"
    static let studyFavoriteAddA11y = "study_favorite_add_a11y"
    static let studyFavoriteHintA11y = "study_favorite_hint_a11y"
    static let studyReverseActiveA11y = "study_reverse_active_a11y"
    static let studyReverseInactiveA11y = "study_reverse_inactive_a11y"
    static let studyReverseHintA11y = "study_reverse_hint_a11y"
    static let studyReverseValueActive = "study_reverse_value_active"
    static let studyReverseValueInactive = "study_reverse_value_inactive"
    static let studyFlashcardSideFrontA11y = "study_flashcard_side_front_a11y"
    static let studyFlashcardSideBackA11y = "study_flashcard_side_back_a11y"
    static let studyFlashcardFlipHintA11y = "study_flashcard_flip_hint_a11y"
    static let studyFlashcardFrontA11y = "study_flashcard_front_a11y"
    static let studyFlashcardBackWithExampleA11y = "study_flashcard_back_with_example_a11y"
    static let studyFlashcardBackWordOnlyA11y = "study_flashcard_back_word_only_a11y"
    
    // Check all button
    static let allSelected = "all_selected"
    
    // Settings
    static let settings = "settings"
    static let settingsSectionAbout = "settings_section_about"
    static let settingsSectionAccess = "settings_section_access"
    static let settingsSectionPersonalization = "settings_section_personalization"
    static let settingsSectionSynchronization = "settings_section_synchronization"
    static let settingsSectionSupport = "settings_section_support"
    static let settingsSectionLegal = "settings_section_legal"
    static let settingsSectionData = "settings_section_data"
    static let about = "about"
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
    static let impressum = "impressum"
    static let termsOfUse = "terms_of_use"
    static let privacyPolicy = "privacy_policy"
    static let resetApp = "reset_app"
    static let resetAppTitle = "reset_app_title"
    static let resetAppMessage = "reset_app_message"
    static let reset = "reset"
    static let cancel = "cancel"
    /// Generic alert title (e.g. purchase / restore errors).
    static let errorAlertTitle = "error_alert_title"
    /// VoiceOver label for paywall dismiss (X) control.
    static let closePaywallA11y = "close_paywall_a11y"

    static let iCloudSync = "icloud_sync"
    static let iCloudSyncFooter = "icloud_sync_footer"
    static let iCloudAccountSignedIn = "icloud_account_signed_in"
    static let iCloudAccountNotSignedIn = "icloud_account_not_signed_in"
    
    // About page
    static let aboutThisApp = "about_this_app"
    /// Text after `aboutThisApp` (starts with a space); then test name, mid, book title, tail (composed in `AboutView`).
    static let aboutAppDescLead = "about_app_desc_lead"
    static let aboutOfficialTestName = "about_official_test_name"
    static let aboutAppDescMid = "about_app_desc_mid"
    static let aboutOfficialBookTitle = "about_official_book_title"
    static let aboutAppDescTail = "about_app_desc_tail"
    static let deviceInformation = "device_information"
    static let name = "name"
    static let version = "version"
    static let model = "model"
    static let systemVersion = "system_version"
    static let appVersion = "app_version"
    static let aboutDebugSetProMode = "about_debug_set_pro_mode"
    static let aboutDebugProModeEnabled = "about_debug_pro_mode_enabled"
    static let aboutDebugRestoreNormalSubscription = "about_debug_restore_normal_subscription"
    static let aboutDebugNormalModeRestoredAll = "about_debug_normal_mode_restored_all"
    static let aboutDebugNormalModeClearedStudy = "about_debug_normal_mode_cleared_study"
    static let aboutDebugProgressPresetFooter = "about_debug_progress_preset_footer"
    static let aboutDebugSheetTitle = "about_debug_sheet_title"
    static let aboutDebugSectionSubscription = "about_debug_section_subscription"
    static let aboutDebugSectionProgressPresets = "about_debug_section_progress_presets"
    static let aboutDebugSectionLastAction = "about_debug_section_last_action"
    static let aboutDebugSetFreeMode = "about_debug_set_free_mode"
    static let aboutDebugFreeModeEnabled = "about_debug_free_mode_enabled"
    /// Format: target percentage (integer).
    static let aboutDebugApplyProgressPreset = "about_debug_apply_progress_preset"
    /// Format: preset target %, current readiness %.
    static let aboutDebugAppliedPresetResult = "about_debug_applied_preset_result"
    
    // Periodicity
    static let hours12 = "12_hours"
    static let hours24 = "24_hours"
    static let hours12Short = "12_hours_short"
    static let hours24Short = "24_hours_short"
    
    // Update (in-app alert)
    static let updateNow = "update_now"
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
    static let progressDescriptionMyWords = "progress_description_my_words"
    static let progressWordScopeApp = "progress_word_scope_app"
    static let progressWordScopeMine = "progress_word_scope_mine"
    static let progressUnderConstruction = "progress_under_construction"
    static let progressComingSoon = "progress_coming_soon"
    static let cockpitMoreFromHeroSubtitle = "cockpit_more_from_hero_subtitle"
    static let cockpitMoreFromHeroBody = "cockpit_more_from_hero_body"
    static let advertisementHeroLeadTitle = "advertisement_hero_lead_title"
    static let advertisementHeroLeadSubtitle = "advertisement_hero_lead_subtitle"
    static let advertisementEinburgerungAppTitle = "advertisement_einburgerung_app_title"
    static let advertisementEinburgerungAppSubtitle = "advertisement_einburgerung_app_subtitle"
    
    // Statistics
    static let statisticsWrongTitle = "statistics_wrong_title"
    static let statisticsFamiliarTitle = "statistics_familiar_title"
    static let statisticsReinforcedTitle = "statistics_reinforced_title"
    static let statisticsMasteredTitle = "statistics_mastered_title"
    static let statisticsWrongDescription = "statistics_wrong_description"
    static let statisticsFamiliarDescription = "statistics_familiar_description"
    static let statisticsReinforcedDescription = "statistics_reinforced_description"
    static let statisticsMasteredDescription = "statistics_mastered_description"
    static let statisticsCardFlipHint = "statistics_card_flip_hint"
    
    // Home Cards
    static let generalWords = "general_words"
    static let adjectivesWithPrepositions = "adjectives_with_prepositions"
    static let favorites = "favorites"
    static let favoritesWordsTitle = "favorites_words_title"
    static let myWords = "my_words"
    static let myWordsAddWord = "my_words_add_word"
    static let myWordsWordOrPhrase = "my_words_word_or_phrase"
    static let myWordsExampleLabel = "my_words_example_label"
    static let myWordsEdit = "my_words_edit"
    static let myWordsDoneEditing = "my_words_done_editing"
    static let myWordsEditWord = "my_words_edit_word"
    static let myWordsFreePlanFooter = "my_words_free_plan_footer"
    static let myWordsDeleteWord = "my_words_delete_word"
    static let myWordsDeleteWordHint = "my_words_delete_word_hint"
    static let myWordsEditRowHint = "my_words_edit_row_hint"
    static let myWordsDeleteAllTitle = "my_words_delete_all_title"
    static let myWordsDeleteAllMessage = "my_words_delete_all_message"
    static let myWordsDeleteAllConfirm = "my_words_delete_all_confirm"
    static let myWordsDeleteAllToolbarHint = "my_words_delete_all_toolbar_hint"
    static let myWordsDeleteAllToolbarLabel = "my_words_delete_all_toolbar_label"
    static let myWordsAddWordA11yHint = "my_words_add_word_a11y_hint"
    static let myWordsAddWordA11yHintLocked = "my_words_add_word_a11y_hint_locked"
    static let myWordsProLockedTitle = "my_words_pro_locked_title"
    static let myWordsProLockedMessage = "my_words_pro_locked_message"
    /// Toolbar overflow menu (My Words).
    static let myWordsMoreOptionsA11y = "my_words_more_options_a11y"
    static let myWordsSortBy = "my_words_sort_by"
    static let myWordsSortTitle = "my_words_sort_title"
    static let myWordsSortCreationDate = "my_words_sort_creation_date"
    static let myWordsSortManual = "my_words_sort_manual"
    static let myWordsSortAscending = "my_words_sort_ascending"
    static let myWordsSortDescending = "my_words_sort_descending"
    static let myWordsSortDateOldestFirst = "my_words_sort_date_oldest_first"
    static let myWordsSortDateNewestFirst = "my_words_sort_date_newest_first"
    static let myWordsPrint = "my_words_print"
    /// VoiceOver: My Words list container.
    static let myWordsListA11yLabel = "my_words_list_a11y_label"
    static let myWordsListA11yHint = "my_words_list_a11y_hint"
    /// %@ = translation text.
    static let myWordsRowTranslationA11yLabel = "my_words_row_translation_a11y_label"
    static let myWordsRowTranslationEditA11yHint = "my_words_row_translation_edit_a11y_hint"
    static let myWordsRowFavoriteAddA11y = "my_words_row_favorite_add_a11y"
    static let myWordsRowFavoriteRemoveA11y = "my_words_row_favorite_remove_a11y"
    static let myWordsRowFavoriteValueYesA11y = "my_words_row_favorite_value_yes_a11y"
    static let myWordsRowFavoriteValueNoA11y = "my_words_row_favorite_value_no_a11y"
    /// %@ = German headword.
    static let myWordsRowFavoriteHintA11y = "my_words_row_favorite_hint_a11y"
    /// %@ = explanation text.
    static let myWordsRowExplanationA11y = "my_words_row_explanation_a11y"
    /// %@ = example text.
    static let myWordsRowExampleA11y = "my_words_row_example_a11y"
    /// %@ = synonyms text.
    static let myWordsRowSynonymsA11y = "my_words_row_synonyms_a11y"
    /// %@ = German headword.
    static let myWordsRowContainerA11y = "my_words_row_container_a11y"

    // Practice button
    static let practice = "practice"
    /// Toolbar label: single word per language (flashcards / Karteikarten).
    static let practiceWithCards = "practice_with_cards"
    static let practiceNeedSelectionTitle = "practice_need_selection_title"
    static let practiceNeedSelectionMessage = "practice_need_selection_message"
    
    // Header Greeting
    /// Single home hero encouragement above the word of the day (fixed-size text well).
    static let heroWordOfTheDayEncouragement = "hero_word_of_the_day_encouragement"
    
    // Pro subscription
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
    static let paywallFooterAlreadySubscribed = "paywall_footer_already_subscribed"
    static let paywallFooterGotCode = "paywall_footer_got_code"
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
    /// Settings Pro banner — opens paywall for subscribers (plans, renewals, restore).
    static let viewProPlans = "view_pro_plans"
    /// Settings — section header above plan row.
    static let settingsSectionHeroPro = "settings_section_hero_pro"
    /// Settings — navigation title & row title.
    static let yourPlan = "your_plan"
    static let planStatusLoading = "plan_status_loading"
    static let planStatusFree = "plan_status_free"
    static let planStatusTrial = "plan_status_trial"
    static let planStatusMonthly = "plan_status_monthly"
    static let planStatusYearly = "plan_status_yearly"
    static let planStatusQuarterly = "plan_status_quarterly"
    static let planStatusLifetime = "plan_status_lifetime"
    /// Active Pro subscription when product id is unknown (e.g. future products).
    static let planStatusHeroProActive = "plan_status_hero_pro_active"
    static let planDetailFreeBody = "plan_detail_free_body"
    static let planDetailTrialBody = "plan_detail_trial_body"
    static let planDetailTrialEndsFormat = "plan_detail_trial_ends_format"
    static let planDetailSubscriptionBody = "plan_detail_subscription_body"
    static let planDetailRenewsFormat = "plan_detail_renews_format"
    static let planDetailLifetimeBody = "plan_detail_lifetime_body"
    static let planDetailLifetimeThanks = "plan_detail_lifetime_thanks"
    static let manageSubscription = "manage_subscription"
    static let manageSubscriptionFailedTitle = "manage_subscription_failed_title"
    static let manageSubscriptionFailed = "manage_subscription_failed"
    static let continueButton = "continue_button"
    static let subscriptionTerms = "subscription_terms"
    static let subscriptionTermsLifetime = "subscription_terms_lifetime"
    static let subscriptionTermsAgreementLine = "subscription_terms_agreement_line"
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
    
    // Pro Lock
    static let premiumRequired = "premium_required"
    static let unlockPremiumToUseFeature = "unlock_premium_to_use_feature"
    static let proFeatureTitle = "pro_feature_title"
    static let proFeatureOnlyMessage = "pro_feature_only_message"
    static let wordListPrintA11yHint = "word_list_print_a11y_hint"
    
    // Rating Prompt
    static let ratingTitle = "rating_title"
    static let ratingSubtitle = "rating_subtitle"
    static let ratingRateButton = "rating_rate_button"
    static let ratingLaterButton = "rating_later_button"
    static let ratingNoThanksButton = "rating_no_thanks_button"
    
    // Share
    static let share = "share"
    static let shareToolbarA11yHint = "share_toolbar_a11y_hint"
    static let shareScreenFooter = "share_screen_footer"
    static let openInAppStore = "open_in_app_store"
    
    // Holiday Seasonal Banner
    static let holidaySeasonSale = "holiday_season_sale"
    static let holidaySeasonSaleDescription = "holiday_season_sale_description"
    static let holidaySeasonSaleDescriptionNoPrice = "holiday_season_sale_description_no_price"
    static let regularPrice = "regular_price"
    static let sale = "sale"
    
}

