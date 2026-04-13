//
//  AppDeepLinkRouter.swift
//  B2 Berufssprachkurs
//
//  Central deep-link router that translates URLs into app navigation routes.
//  Created: 10.04.26.
//

import Combine
import Foundation

// MARK: - Deep Link Routing

@MainActor
final class AppDeepLinkRouter: ObservableObject {
    static let shared = AppDeepLinkRouter()

    /// One atomic UI action per URL. `MainView` is the single consumer; it sets this back to `nil` after handling.
    enum PendingRoute: Equatable {
        case tab(MainViewSection)
        /// Widgets open the app without changing tab; consumes the URL so dedup state stays correct.
        case foregroundOnly
        /// Quick Add: present composer sheet only (same tab / navigation stack as before).
        case myWordsComposer
        /// Open Study with "My Words" source.
        case myWordsStudy
    }

    @Published private(set) var pendingRoute: PendingRoute?

    private var lastHandledURL: URL?
    private var lastHandledAt: Date?

    private init() {}

    func handle(url: URL) {
        guard url.scheme == "b2beruf" || url.scheme == "heroapp" else { return }

        let now = Date()
        if let prior = lastHandledURL,
           prior.scheme?.lowercased() == url.scheme?.lowercased(),
           prior.host == url.host,
           prior.path == url.path,
           now.timeIntervalSince(lastHandledAt ?? .distantPast) < 0.4 {
            return
        }
        lastHandledURL = url
        lastHandledAt = now

        let host = url.host ?? ""
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let route = [host, path]
            .filter { !$0.isEmpty }
            .joined(separator: "/")

        switch route {
        case "home":
            pendingRoute = .tab(.home)
        case "cockpit":
            pendingRoute = .tab(.cockpit)
        case "settings":
            pendingRoute = .tab(.settings)
        case "mywords/add", "quickadd":
            pendingRoute = .myWordsComposer
        case "mywords/study", "mywords/learn":
            pendingRoute = .myWordsStudy
        case "wotd":
            pendingRoute = .foregroundOnly
        default:
            break
        }
    }

    /// Call after applying `pendingRoute` in UI so the next open does not replay the same route.
    func clearPendingRoute() {
        pendingRoute = nil
    }
}
