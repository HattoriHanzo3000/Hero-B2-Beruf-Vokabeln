//
//  StudyEmptyStateView.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI

struct StudyEmptyStateView: View {
    let title: String
    let message: String
    let iconName: String
    /// Study screen canvas; ``StudyView`` passes the resolved color (light: grouped gray, dark: systemBackground).
    var backgroundColor: Color = Color(.systemGroupedBackground)

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Empty state content
                VStack(spacing: 20) {
                    Image(systemName: iconName)
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    
                    Text(title)
                        .font(.system(.title3, design: .default).weight(.regular))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text(message)
                        .font(.system(.body, design: .default))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .accessibilityElement(children: .combine)
                
                Spacer()
            }
        }
    }
}

#Preview {
    StudyEmptyStateView(
        title: "Keine Wörter ausgewählt",
        message: "Wähle die Wörter mit dem Häkchen aus",
        iconName: "checkmark.circle"
    )
}
