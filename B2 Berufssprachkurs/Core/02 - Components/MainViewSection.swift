//
//  MainViewSection.swift
//  B2 Berufssprachkurs
//
//  Identifies which root area is selected in the main `TabView`. Most raw values match `Localizable` keys;
//  `search` uses the system search tab role (icon-only).
//

import SwiftUI

enum MainViewSection: String, CaseIterable {
    case home = "home"
    case cockpit = "cockpit"
    case search = "search"
    case settings = "settings"

    var icon: String {
        switch self {
        case .home:
            return "square.stack.3d.up.fill"
        case .cockpit:
            return "gauge"
        case .search:
            return "magnifyingglass"
        case .settings:
            return "gear"
        }
    }

    var localizedTitle: String {
        switch self {
        case .search:
            return Localizable.string(Localizable.tabSearchAccessibility)
        default:
            return Localizable.string(self.rawValue)
        }
    }
}
