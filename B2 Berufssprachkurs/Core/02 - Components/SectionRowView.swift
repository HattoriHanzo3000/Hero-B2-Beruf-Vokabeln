//
//  SectionRowView.swift
//  B2 Berufssprachkurs
//
//  Subsection row under an expanded lection: checkmark, letter chip (non-VERBEN), title, navigation to `WordsListView` or PRO tap when locked.
//

import SwiftUI

struct SectionRowView: View {
    let section: Section
    let lection: Lection
    @ObservedObject var dataService: DataService
    var isLocked: Bool = false
    var onPaywall: () -> Void = {}
    @Environment(\.colorScheme) private var colorScheme

    private var subsectionCheckmarkFillColor: Color {
        guard dataService.isSectionCompleted(sectionId: section.id) else { return .secondary }
        return dataService.isEverySectionCompleted(in: lection)
            ? CompletionCheckmarkPalette.fullFill(colorScheme)
            : CompletionCheckmarkPalette.partialFill(colorScheme)
    }

    /// Extract letter from section ID (e.g., "1A" -> "a").
    private var sectionLetter: String {
        let lastChar = section.id.last?.lowercased() ?? ""
        return lastChar
    }

    /// VERBEN sections omit the letter chip.
    private var isVerbenSection: Bool {
        section.id.hasPrefix("VERBEN_")
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                if isLocked {
                    onPaywall()
                } else {
                    HapticManager.shared.lightImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dataService.toggleSectionCompleted(sectionId: section.id)
                    }
                }
            }) {
                Image(systemName: dataService.isSectionCompleted(sectionId: section.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(.subheadline, design: .default).weight(.medium))
                    .foregroundColor(subsectionCheckmarkFillColor)
                    .symbolEffect(.bounce, value: dataService.isSectionCompleted(sectionId: section.id))
            }
            .buttonStyle(.plain)

            rowLabelContent
        }
        .padding(.leading, 16)
        .opacity(isLocked ? 0.65 : 1.0)
    }

    @ViewBuilder
    private var rowLabelContent: some View {
        let label = HStack(spacing: 12) {
            if !sectionLetter.isEmpty && !isVerbenSection {
                Text(sectionLetter.uppercased())
                    .font(.system(.body, design: .default))
                    .fontWeight(.medium)
                    .foregroundColor(Color("AppGreen"))
            }

            Text(section.title)
                .font(.system(.subheadline, design: .default))
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
        }
        .padding(.vertical, 4)
        .padding(.leading, 6)
        .frame(maxWidth: .infinity, alignment: .leading)

        if isLocked {
            Button(action: onPaywall) {
                label
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(destination: WordsListView(sectionId: section.id)
                .environmentObject(dataService)) {
                label
            }
        }
    }
}
