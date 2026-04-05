//
//  FavoriteGroupType+SwiftUI.swift
//  B2 Berufssprachkurs
//

import SwiftUI

extension FavoriteGroupType {
    var color: Color {
        switch self {
        case .generalWords:
            Color("AppGreen")
        case .verbs:
            Color("AppBlue")
        case .adjectives:
            Color("AppPurple")
        case .myWords:
            Color("AppRed")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .generalWords:
            Color("AppGreen").opacity(0.08)
        case .verbs:
            Color("AppBlue").opacity(0.08)
        case .adjectives:
            Color("AppPurple").opacity(0.08)
        case .myWords:
            Color("AppRed").opacity(0.08)
        }
    }
}
