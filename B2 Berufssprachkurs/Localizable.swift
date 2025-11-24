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
    static let translation = "translation"
    
    // Tab Bar
    static let words = "words"
    static let verbs = "verbs"
    
    // Practice buttons
    static let practiseWithExample = "practise_with_example"
    
    // Study view
    static let cards = "cards"
    
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
    
    // Update page
    static let currentVersion = "current_version"
    static let updateAvailable = "update_available"
    static let versionUpdates = "version_updates"
    static let versionUpdatesPlaceholder = "version_updates_placeholder"
    static let updateNow = "update_now"
    static let updateButtonHint = "update_button_hint"
}

