import SwiftUI

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
struct ProShieldBadge: View {
    let label: String
    var color: Color = .white
    /// When true, applies shimmer overlay.
    var showShimmer: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(label.uppercased())
            .font(.system(.caption2, weight: .medium).width(.expanded))
            .foregroundColor(color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(color, lineWidth: 0.6)
            )
            .overlay(shimmerOverlay)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var shimmerOverlay: some View {
        if showShimmer && !reduceMotion {
            ShimmerOverlay(duration: 4)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .blendMode(.plusLighter)
        }
    }
}
