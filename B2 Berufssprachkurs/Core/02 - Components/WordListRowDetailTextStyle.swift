//
//  WordListRowDetailTextStyle.swift
//  B2 Berufssprachkurs
//
//  List row detail typography (localized short prefixes). Word-of-the-day in `HeaderView` uses its own fonts.
//

import SwiftUI

enum WordListRowDetailTextStyle {
    /// Erklärung, Beispiel, Synonyme — shared weight for secondary detail lines in list rows.
    static let explanationLabelFont = Font.system(.subheadline, design: .default, weight: .semibold).width(.condensed)
    static let explanationValueFont = Font.system(.subheadline, design: .default, weight: .regular).width(.condensed)
}
