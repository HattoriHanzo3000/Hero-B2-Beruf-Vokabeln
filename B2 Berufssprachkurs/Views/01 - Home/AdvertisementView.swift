//
//  AdvertisementView.swift
//  B2 Berufssprachkurs
//
//  Sheet for cockpit “More from Hero” — paywall-style green gradient shell.
//

import SwiftUI

struct AdvertisementView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PaywallBackground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .navigationBarSymbolStyle()
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    AdvertisementView()
}
