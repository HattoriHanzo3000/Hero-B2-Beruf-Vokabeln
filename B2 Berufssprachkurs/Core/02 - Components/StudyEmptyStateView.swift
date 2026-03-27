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
    
    var body: some View {
        ZStack {
            Color("AppGreenLight")
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
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text(message)
                        .font(.system(.body, design: .rounded))
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
