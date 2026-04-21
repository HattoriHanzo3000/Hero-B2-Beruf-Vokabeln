//
//  FloatingKeyboardAccessorySupport.swift
//  B2 Berufssprachkurs
//
//  Metrics, press zones, and liquid-glass styling for the keyboard accessory pill.
//
//  Created: 21.04.26.
//

import SwiftUI

// MARK: - Helpers

enum FloatingAccessoryMetrics {
    static let pillHeight: CGFloat = 44
    static let touchTargetMin: CGFloat = 44
    static let bottomGap: CGFloat = 10
    static let horizontalInset: CGFloat = 12
    static let contentHorizontalPadding: CGFloat = 6

    static let iconPointSize: CGFloat = 17
    static let rimLineWidth: CGFloat = 0.5

    static let pressedScale: CGFloat = 1.05
    static let pressSpring: Animation = .spring(response: 0.3, dampingFraction: 0.7)

    static let glowBlurRadius: CGFloat = 8
    static let glowEndRadiusFactor: CGFloat = 0.6

    static let shadowOpacityIdle: Double = 0.14
    static let shadowOpacityPressed: Double = 0.22
    static let shadowRadiusIdle: CGFloat = 12
    static let shadowRadiusPressed: CGFloat = 18
    static let shadowYOffsetIdle: CGFloat = 6
    static let shadowYOffsetPressed: CGFloat = 10

    static let visibilitySpring: Animation = .spring(response: 0.38, dampingFraction: 0.86)
    static let previewKeyboardStripHeightFactor: CGFloat = 0.36
}

enum PillZone: Hashable {
    case previous
    case next
    case done
}

struct LiquidGlassHighlight: View {
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .white.opacity(0.55),
                        .white.opacity(0.15),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: FloatingAccessoryMetrics.touchTargetMin * FloatingAccessoryMetrics.glowEndRadiusFactor
                )
            )
            .blur(radius: FloatingAccessoryMetrics.glowBlurRadius)
            .scaleEffect(isActive ? 1.0 : 0.6)
            .opacity(isActive ? 1.0 : 0.0)
            .animation(FloatingAccessoryMetrics.pressSpring, value: isActive)
            .allowsHitTesting(false)
    }
}

struct LiquidGlassPressStyle: ButtonStyle {
    let zone: PillZone
    @Binding var pressedZones: Set<PillZone>

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background {
                LiquidGlassHighlight(isActive: configuration.isPressed)
            }
            .onChange(of: configuration.isPressed) { _, isPressed in
                withAnimation(FloatingAccessoryMetrics.pressSpring) {
                    if isPressed {
                        pressedZones.insert(zone)
                    } else {
                        pressedZones.remove(zone)
                    }
                }
            }
    }
}

struct FloatingAccessoryIcon: View {
    let systemName: String
    var weight: Font.Weight = .semibold

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: FloatingAccessoryMetrics.iconPointSize, weight: weight))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.primary)
            .frame(minWidth: FloatingAccessoryMetrics.touchTargetMin, minHeight: FloatingAccessoryMetrics.touchTargetMin)
    }
}
