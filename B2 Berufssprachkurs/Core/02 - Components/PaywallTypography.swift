//
//  PaywallTypography.swift
//  B2 Berufssprachkurs
//
//  SF Pro width variants for paywall plan subtitles (matches Hero-style rows).
//

import SwiftUI
import UIKit

extension Font {
    /// SF Pro Condensed Regular at caption size (respects Dynamic Type).
    static var paywallSubtitleCondensed: Font {
        Font(UIFont.systemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize,
            weight: .regular,
            width: .condensed
        ))
    }

    /// SF Pro Expanded Regular at caption size (for "Ends in" + countdown).
    static var paywallSubtitleExpanded: Font {
        Font(UIFont.systemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize,
            weight: .regular,
            width: .expanded
        ))
    }
}
