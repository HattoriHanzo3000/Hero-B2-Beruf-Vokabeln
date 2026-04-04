//
//  StudyItem.swift
//  B2 Berufssprachkurs
//

import SwiftUI

struct StudyItem: Equatable {
    let wordId: String
    let sectionId: String
    let germanWord: String
    let synonym: String?
    let explanation: String?
    let translation: String?
    let quiz: String?
    let example: String?
    let isVerbenSection: Bool
}

extension StudyItem {
    /// Accent for flashcard chrome (matches section kind: course, Verben, Adjektive, Meine Wörter).
    var accentColor: Color {
        if sectionId == DataService.userMyWordsSectionId {
            return Color("AppRed")
        }
        if isVerbenSection {
            return Color("AppBlue")
        }
        if sectionId.hasPrefix("ADJEKTIVE_") {
            return Color("AppPurple")
        }
        return Color("AppGreen")
    }
}
