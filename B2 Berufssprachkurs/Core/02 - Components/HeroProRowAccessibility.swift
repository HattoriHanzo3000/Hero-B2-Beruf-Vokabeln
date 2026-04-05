//
//  HeroProRowAccessibility.swift
//  B2 Berufssprachkurs
//

import SwiftUI

struct HeroProRowAccessibility: ViewModifier {
    let useCombinedLabel: Bool
    let combinedLabel: String

    func body(content: Content) -> some View {
        if useCombinedLabel {
            content
                .accessibilityElement(children: .combine)
                .accessibilityLabel(combinedLabel)
        } else {
            content
        }
    }
}
