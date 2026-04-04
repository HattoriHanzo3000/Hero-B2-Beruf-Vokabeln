//
//  LectionHeaderView.swift
//  B2 Berufssprachkurs
//
//  Expandable lection header for the General Words list: completion checkmark + title row + PRO badge when locked.
//

import SwiftUI

struct LectionHeaderView: View {
    let lection: Lection
    let isExpanded: Bool
    let onToggle: () -> Void
    @ObservedObject var dataService: DataService
    /// When true, the lection checkmark opens the paywall; expand/collapse still works so users can browse subsections.
    var isLocked: Bool = false
    var onPaywall: () -> Void = {}
    @Environment(\.colorScheme) private var colorScheme

    /// 0 = none, 1 = partial (lighter fill), 2 = all sections done (darker fill).
    private var lectionCheckmarkTier: Int {
        if dataService.isEverySectionCompleted(in: lection) { return 2 }
        if dataService.isAnySectionCompleted(in: lection) { return 1 }
        return 0
    }

    private var lectionCheckmarkForeground: Color {
        switch lectionCheckmarkTier {
        case 2: return CompletionCheckmarkPalette.fullFill(colorScheme)
        case 1: return CompletionCheckmarkPalette.partialFill(colorScheme)
        default: return Color.secondary
        }
    }

    /// Sized like the list `NavigationLink` disclosure (footnote + semibold); a touch darker than `.secondary`.
    private var lectionDisclosureChevronColor: Color {
        switch colorScheme {
        case .dark:
            return Color.primary.opacity(0.52)
        case .light:
            fallthrough
        @unknown default:
            return Color.primary.opacity(0.46)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                if isLocked {
                    onPaywall()
                } else {
                    HapticManager.shared.lightImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataService.toggleLectionCompleted(lectionId: lection.id)
                    }
                }
            }) {
                Image(systemName: lectionCheckmarkTier == 0 ? "circle" : "checkmark.circle.fill")
                    .font(.system(.callout, design: .default).weight(.medium))
                    .foregroundColor(lectionCheckmarkForeground)
                    .symbolEffect(.bounce, value: lectionCheckmarkTier)
            }
            .buttonStyle(.plain)

            // Expand/collapse — always allowed so free users can unfold and see locked subsections.
            Button(action: {
                HapticManager.shared.selection()
                onToggle()
            }) {
                HStack {
                    Image(systemName: "\(lection.id).circle.fill")
                        .font(.system(.title2, design: .default).weight(.medium))
                        .foregroundColor(Color("AppGreen"))

                    Text(lection.title)
                        .font(.system(.title3, design: .default))
                        .foregroundColor(.primary)

                    if isLocked {
                        ProShieldBadge(
                            label: "PRO",
                            color: Color.primary.opacity(0.72),
                            showShimmer: false,
                            style: .compact
                        )
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(.footnote, design: .default).weight(.semibold))
                        .foregroundColor(lectionDisclosureChevronColor)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
