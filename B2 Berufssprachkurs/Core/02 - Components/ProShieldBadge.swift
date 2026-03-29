import SwiftUI
import UIKit

// MARK: - Shimmer Overlay (reusable for badges)
private struct ShimmerOverlay: View {
    var duration: Double = 4
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.5), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.5)
            .offset(x: phase * geo.size.width * 1.8 - geo.size.width * 0.5)
        }
        .onAppear {
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

// MARK: - Pro badge (decorative, non-interactive)
// Copied design from Hero: rounded rect stroke + SF Pro Expanded uppercase + shimmer overlay.
enum ProShieldBadgeStyle: Sendable {
    /// Header, paywall, cockpit promos.
    case standard
    /// Inline list rows (e.g. Word of the Day section picks).
    case compact
}

struct ProShieldBadge: View {
    let label: String
    var color: Color = .white
    /// When true, applies shimmer overlay.
    var showShimmer: Bool = false
    var style: ProShieldBadgeStyle = .standard

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cornerRadius: CGFloat {
        switch style {
        case .standard: 6
        case .compact: 4
        }
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .standard: 6
        case .compact: 4
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .standard: 3
        case .compact: 2
        }
    }

    private var strokeLineWidth: CGFloat {
        switch style {
        case .standard: 0.6
        case .compact: 0.55
        }
    }

    private var labelFont: Font {
        switch style {
        case .standard:
            return .system(.caption2, weight: .medium).width(.expanded)
        case .compact:
            return Font(UIFont.systemFont(ofSize: 9, weight: .medium, width: .expanded))
        }
    }

    var body: some View {
        Text(label.uppercased())
            .font(labelFont)
            .foregroundColor(color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color, lineWidth: strokeLineWidth)
            )
            .overlay(shimmerOverlay)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var shimmerOverlay: some View {
        if showShimmer && !reduceMotion {
            ShimmerOverlay(duration: 4)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .blendMode(.plusLighter)
        }
    }
}
