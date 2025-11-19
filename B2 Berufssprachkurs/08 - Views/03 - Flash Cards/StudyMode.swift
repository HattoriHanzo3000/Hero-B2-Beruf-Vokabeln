//
//  StudyMode.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

enum StudyMode {
    case synonyms
    case explanation
    case translations
    
    init(from buttonType: ToolbarButtonType) {
        switch buttonType {
        case .explanation:
            self = .explanation
        case .synonym:
            self = .synonyms
        case .translation:
            self = .translations
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .synonyms:
            return Color("AppGreenLight")
        case .explanation:
            return Color("AppOrangeLight")
        case .translations:
            return Color("AppBlueLight")
        }
    }
    
    var accentColor: Color {
        switch self {
        case .synonyms:
            return Color("AppGreen")
        case .explanation:
            return Color("AppOrange")
        case .translations:
            return Color("AppBlue")
        }
    }
    
    var title: String {
        switch self {
        case .synonyms:
            return "Synonyme"
        case .explanation:
            return "Erklärung"
        case .translations:
            return "Übersetzung"
        }
    }
}

