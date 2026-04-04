//
//  AppStoreArtworkLookup.swift
//  B2 Berufssprachkurs
//
//  Fetches App Store listing artwork via the iTunes Lookup API.
//

import Foundation

enum AppStoreArtworkLookup {
    /// Public iTunes Search API — returns the same artwork URLs the App Store uses for the listing.
    static func artworkURL(appID: Int, countryCode: String = "de") async -> URL? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")!
        components.queryItems = [
            URLQueryItem(name: "id", value: String(appID)),
            URLQueryItem(name: "country", value: countryCode)
        ]
        guard let url = components.url else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            let decoded = try JSONDecoder().decode(ITunesLookupResponse.self, from: data)
            guard let first = decoded.results.first else { return nil }
            let string = first.artworkUrl512 ?? first.artworkUrl100 ?? first.artworkUrl60
            guard let s = string, let artworkURL = URL(string: s) else { return nil }
            return artworkURL
        } catch {
            return nil
        }
    }
}
