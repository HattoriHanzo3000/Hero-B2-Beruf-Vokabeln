//
//  HeroWidgetBackground.swift
//  HeroB2Widgets
//

import SwiftUI

struct HeroWidgetBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Liquid Glass island style from HeaderView+Chrome.swift
            
            // Material blur
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)

            // Green-Blue Tint
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(heroIslandGreenBlueTint)

            // Contrast overlay
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(colorScheme == .dark ? 0.28 : 0.09))
            
            // Border stroke
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.22 : 0.45),
                            Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
    
    private var heroIslandGreenBlueTint: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color("AppGreen").opacity(0.62),
                    Color("AppBlue").opacity(0.55)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color("AppGreen").opacity(0.52),
                    Color("AppBlue").opacity(0.46)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
