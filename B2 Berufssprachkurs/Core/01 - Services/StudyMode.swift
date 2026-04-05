//
//  StudyMode.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

/// Spaced-repetition lane per flashcard chip: synonym, explanation, or translation (example sentences are not a separate lane).
enum StudyMode: CaseIterable {
    case synonyms
    case explanation
    case translations
}
