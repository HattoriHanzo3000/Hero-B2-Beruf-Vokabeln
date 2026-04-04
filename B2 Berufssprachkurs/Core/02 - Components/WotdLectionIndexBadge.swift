//
//  WotdLectionIndexBadge.swift
//  B2 Berufssprachkurs
//

import SwiftUI

/// Card-header index in a circle. Fixed font size so badges stay on-grid when Dynamic Type is large (titles still scale).
enum WotdLectionIndexBadge {
    static let circleSize: CGFloat = 34
    /// `Font.system(size:)` does not follow Dynamic Type.
    static let numberFont = Font.system(size: 22, weight: .semibold, design: .default)

    static func circle(numberText: String, fillColor: Color) -> some View {
        ZStack {
            Circle()
                .fill(fillColor)
                .frame(width: circleSize, height: circleSize)
            Text(numberText)
                .font(numberFont)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
    }
}
