//
//  AppStoreService.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import Foundation

struct AppStoreService {
    static let shared = AppStoreService()
    
    private let bundleId = "com.gizatech.B2-Beruf"
    
    private init() {}
    
    /// Fetches app information including version and release notes from the App Store
    func fetchAppInfo() async throws -> AppStoreApp? {
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
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
