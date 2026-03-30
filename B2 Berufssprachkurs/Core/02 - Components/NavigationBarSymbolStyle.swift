//
//  NavigationBarSymbolStyle.swift
//  B2 Berufssprachkurs
//
//  Shared SF Symbol metrics for navigation bars and toolbars (aligned with list export toolbar buttons).
//

import SwiftUI

extension View {
    /// Standard `.body` + `.medium` weight for toolbar / navigation bar SF Symbols.
    func navigationBarSymbolStyle() -> some View {
        self.font(.body).fontWeight(.medium)
    }
}
