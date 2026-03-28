//
//  WordListRowDetailTextStyle.swift
//  B2 Berufssprachkurs
//
//  List row detail typography (`erkl:`, `beisp:`, `syn:`). Word-of-the-day in `HeaderView` stays heavier for emphasis.
//

import SwiftUI

enum WordListRowDetailTextStyle {
    /// Synonyms (and other lines that stay a touch stronger).
    static let labelFont = Font.system(.subheadline, design: .default, weight: .bold).width(.condensed)
    static let valueFont = Font.system(.subheadline, design: .default, weight: .medium).width(.condensed)
    /// Erklärung & Beispiel: one weight step lighter than `labelFont` / `valueFont`.
    static let explanationLabelFont = Font.system(.subheadline, design: .default, weight: .semibold).width(.condensed)
    static let explanationValueFont = Font.system(.subheadline, design: .default, weight: .regular).width(.condensed)
}
