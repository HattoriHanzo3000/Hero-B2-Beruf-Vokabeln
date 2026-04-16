//
//  WidgetBackgroundView.swift
//  B2 Berufssprachkurs
//
//  Shared background layers for home-screen widgets and lock-screen accessories.
//  Created: 07.04.26.
//

import SwiftUI

private struct HeroIslandLiquidChrome<S: InsettableShape>: View {
    let shape: S
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            shape.fill(.ultraThinMaterial)
            shape.fill(heroIslandGreenBlueTint)
            shape.fill(Color.black.opacity(colorScheme == .dark ? 0.24 : 0.03))
            shape.strokeBorder(
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
            LinearGradient(
                colors: [
                    Color("AppGreen").opacity(0.62),
                    Color("AppBlue").opacity(0.55)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            LinearGradient(
                colors: [
                    Color("AppGreen").opacity(0.70),
                    Color("AppBlue").opacity(0.64)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

struct WidgetBackgroundView: View {
    var body: some View {
        HeroIslandLiquidChrome(shape: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
