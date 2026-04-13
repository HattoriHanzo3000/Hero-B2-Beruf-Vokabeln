//
//  StudyMode.swift
//  B2 Berufssprachkurs
//
//  Declares study mode options and related display metadata.
//  Created: 19.11.25.
//

// MARK: - StudyMode

enum StudyMode: CaseIterable {
    case synonyms
    case explanation
    case translations

    /// Storage key suffix / persisted `studyModeRaw` (see ``SpacedRepetitionService/modeKey(_:)``).
    init?(modeKey: String) {
        switch modeKey {
        case "synonyms": self = .synonyms
        case "explanation": self = .explanation
        case "translations": self = .translations
        default: return nil
        }
    }
}
