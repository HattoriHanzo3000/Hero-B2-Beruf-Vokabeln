//
//  StudyContentTypeChipRow.swift
//  B2 Berufssprachkurs
//

import SwiftUI

struct StudyContentTypeChipRow: View {
    let item: StudyItem
    @Binding var currentContentType: StudyCardContentType
    @Binding var showTranslationMissingAlert: Bool

    var body: some View {
        let currentCardColor = item.accentColor
        let displayTypes = StudyCardContentSupport.displayTypes(for: item)

        if !displayTypes.isEmpty {
            HStack(spacing: 8) {
                ForEach(displayTypes, id: \.self) { type in
                    let isSelected = currentContentType == type
                    let isAvailable = StudyCardContentSupport.isContentTypeAvailable(type, for: item)

                    Button(action: {
                        if isAvailable {
                            HapticManager.shared.lightImpact()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentContentType = type
                            }
                        } else {
                            HapticManager.shared.heavyImpact()
                            showTranslationMissingAlert = true
                        }
                    }) {
                        Text(StudyCardContentSupport.typeButtonTitle(for: type))
                            .font(.system(.caption, design: .default).weight(.regular).width(.expanded))
                            .foregroundColor(
                                !isAvailable ? .secondary.opacity(0.5) :
                                    isSelected ? .white : .primary
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        isSelected && isAvailable ? currentCardColor : Color(.systemGray5)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
