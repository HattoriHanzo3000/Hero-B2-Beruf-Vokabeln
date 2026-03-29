//
//  AppFont.swift
//  B2 Berufssprachkurs
//
//  SF Pro system fonts with width variants (condensed, expanded, standard) via UIKit.
//  Pass `DynamicTypeSize` from `@Environment(\.dynamicTypeSize)` so fonts track accessibility text sizes.
//

import SwiftUI
import UIKit

enum AppFont {
    /// Maps SwiftUI settings to UIKit's content size category for `UIFontMetrics`.
    private static func uiContentSizeCategory(for dynamicTypeSize: DynamicTypeSize) -> UIContentSizeCategory {
        switch dynamicTypeSize {
        case .xSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .extraLarge
        case .xxLarge: return .extraExtraLarge
        case .xxxLarge: return .extraExtraExtraLarge
        case .accessibility1: return .accessibilityMedium
        case .accessibility2: return .accessibilityLarge
        case .accessibility3: return .accessibilityExtraLarge
        case .accessibility4: return .accessibilityExtraExtraLarge
        case .accessibility5: return .accessibilityExtraExtraExtraLarge
        @unknown default: return .large
        }
    }

    private static func sfPro(
        _ textStyle: UIFont.TextStyle,
        weight: UIFont.Weight = .regular,
        width: UIFont.Width = .standard,
        dynamicTypeSize: DynamicTypeSize
    ) -> Font {
        let baseTraits = UITraitCollection(preferredContentSizeCategory: .large)
        let baseSize = UIFont.preferredFont(forTextStyle: textStyle, compatibleWith: baseTraits).pointSize
        let baseFont = UIFont.systemFont(ofSize: baseSize, weight: weight, width: width)
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        let traits = UITraitCollection(preferredContentSizeCategory: uiContentSizeCategory(for: dynamicTypeSize))
        let scaled = metrics.scaledFont(for: baseFont, compatibleWith: traits)
        return Font(scaled)
    }

    /// SF Pro Condensed Regular at caption1 size (scales with Dynamic Type).
    static func caption1CondensedRegular(dynamicTypeSize: DynamicTypeSize) -> Font {
        sfPro(.caption1, weight: .regular, width: .condensed, dynamicTypeSize: dynamicTypeSize)
    }

    /// SF Pro Expanded Regular at caption1 size (scales with Dynamic Type).
    static func caption1ExpandedRegular(dynamicTypeSize: DynamicTypeSize) -> Font {
        sfPro(.caption1, weight: .regular, width: .expanded, dynamicTypeSize: dynamicTypeSize)
    }

    /// SF Pro Condensed Regular at subheadline size (scales with Dynamic Type).
    static func subheadlineCondensedRegular(dynamicTypeSize: DynamicTypeSize) -> Font {
        sfPro(.subheadline, weight: .regular, width: .condensed, dynamicTypeSize: dynamicTypeSize)
    }

    /// SF Pro Expanded at a fixed size (e.g. cockpit chips where Dynamic Type is clamped).
    static func fixedExpanded(size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        Font(UIFont.systemFont(ofSize: size, weight: weight, width: .expanded))
    }
}
