//
//  ITunesLookupModels.swift
//  B2 Berufssprachkurs
//
//  Decodable shapes for the public iTunes Lookup API (artwork URLs, etc.).
//

import Foundation

struct ITunesLookupResponse: Decodable {
    let results: [ITunesLookupAppResult]
}

struct ITunesLookupAppResult: Decodable {
    let artworkUrl60: String?
    let artworkUrl100: String?
    let artworkUrl512: String?
}
