//
//  AppExternalLinks.swift
//  B2 Berufssprachkurs
//
//  Central place for web URLs, in-app link schemes, iTunes API roots, and support email.
//  Canonical App Store *listing* strings for **this** app remain in `AppStoreService` (avoids circular refs).
//

import Foundation

enum AppExternalLinks {
    // MARK: - App identity

    static let appBundleIdentifier = "com.gizatech.B2-Beruf"
    static let supportEmail = "info@gizatech.de"

    // MARK: - Web (gizatech — Hero B2 Beruf)

    private static let heroB2BerufBaseURLString = "https://www.gizatech.de/hero-b2-beruf"

    /// Company homepage (e.g. previews / generic web).
    static let companyWebsite: URL = URL(string: "https://www.gizatech.de")!

    static let legalImpressum: URL = URL(string: "\(heroB2BerufBaseURLString)/impressum")!
    static let legalTermsOfUse: URL = URL(string: "\(heroB2BerufBaseURLString)/terms-of-use")!
    static let legalPrivacyPolicy: URL = URL(string: "\(heroB2BerufBaseURLString)/privacy-policy")!

    // MARK: - Markdown / in-app schemes

    /// Must stay in sync with `subscription_terms_agreement_line` in Localizable strings (markdown links).
    static let subscriptionTermsLinkScheme = "hero://terms"
    static let subscriptionPrivacyLinkScheme = "hero://privacy"

    // MARK: - iTunes Search API

    static let iTunesLookupAPIURL = URL(string: "https://itunes.apple.com/lookup")!

    static func iTunesLookupURL(bundleId: String = appBundleIdentifier) -> URL? {
        var components = URLComponents(url: iTunesLookupAPIURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "bundleId", value: bundleId)]
        return components?.url
    }

    // MARK: - Other App Store listings (cross-promo)

    enum CrossPromo {
        /// “Hero – Einbürgerungstest” (App Store Connect).
        static let einburgerungAppStoreNumericID = 6_752_272_685

        static var einburgerungAppStoreURL: URL {
            URL(string: "https://apps.apple.com/app/id\(einburgerungAppStoreNumericID)")!
        }
    }
}
