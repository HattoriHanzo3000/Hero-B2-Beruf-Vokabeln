//
//  AppStoreService.swift
//  B2 Berufssprachkurs
//
//  Fetches and formats App Store metadata for update and sharing flows.
//  Created: 09.12.25.
//

import Foundation

// MARK: - Service

struct AppStoreService {
    static let shared = AppStoreService()

    /// Numeric App Store ID (App Store Connect → General → Apple ID).
    static let appStoreNumericID = 6_755_700_752

    /// Canonical listing URL when region should follow the user’s storefront.
    static var defaultListingURL: String {
        "https://apps.apple.com/app/id\(appStoreNumericID)"
    }

    /// Direct link to the App Store write-review sheet (Settings → Rate the app).
    static var appStoreWriteReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreNumericID)?action=write-review")!
    }

    /// Prefer the ID returned by iTunes Lookup (`trackId`); fall back to `defaultListingURL`.
    static func listingURL(preferredTrackId: Int?) -> String {
        if let preferredTrackId {
            return "https://apps.apple.com/app/id\(preferredTrackId)"
        }
        return defaultListingURL
    }
    
    private init() {}
    
    /// Fetches app information including version and release notes from the App Store
    func fetchAppInfo() async throws -> AppStoreApp? {
        guard let url = AppExternalLinks.iTunesLookupURL() else {
            return nil
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let response = try decoder.decode(AppStoreResponse.self, from: data)
        
        return response.results.first
    }
    
    /// Formats release notes by cleaning HTML tags
    func formatReleaseNotes(_ notes: String) -> String {
        // Remove HTML tags if present
        var cleaned = notes
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clean up multiple newlines
        cleaned = cleaned.replacingOccurrences(of: "\n\n+", with: "\n\n", options: .regularExpression)
        
        return cleaned
    }
}

// MARK: - App Store API Models

struct AppStoreResponse: Codable {
    let results: [AppStoreApp]
}

struct AppStoreApp: Codable {
    let version: String
    let releaseNotes: String?
    let trackId: Int?
    
    enum CodingKeys: String, CodingKey {
        case version
        case releaseNotes
        case trackId
    }
}
