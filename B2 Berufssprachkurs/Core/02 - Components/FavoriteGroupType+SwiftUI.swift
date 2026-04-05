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
            LearningSurfaceColors.generalWords
        case .verbs:
            LearningSurfaceColors.verbs
        case .adjectives:
            LearningSurfaceColors.adjectives
        case .myWords:
            LearningSurfaceColors.myWords
        }
    }
}
