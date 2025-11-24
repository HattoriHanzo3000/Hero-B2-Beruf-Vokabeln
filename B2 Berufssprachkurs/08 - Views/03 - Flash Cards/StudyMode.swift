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
    case example // For VERBEN sections with quiz sentences
    
    init(from buttonType: ToolbarButtonType) {
        switch buttonType {
        case .explanation:
            self = .explanation
        case .synonym:
            self = .synonyms
        case .translation:
            self = .translations
        case .example:
            self = .example
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
        case .example:
            return Color("AppOrangeLight") // Same as explanation
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
        case .example:
            return Color("AppOrange") // Same as explanation
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
        case .example:
            return Localizable.string(Localizable.practiseWithExample)
        }
    }
}

