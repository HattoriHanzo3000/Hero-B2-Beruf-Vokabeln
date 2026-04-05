//
//  RatingPromptOverlay.swift
//  B2 Berufssprachkurs
//
//  Full-screen dimming + `RatingPromptView` when the app asks for an App Store rating.
//

import SwiftUI

struct RatingPromptOverlay: View {
    @ObservedObject var ratingManager: RatingManager

    var body: some View {
        Group {
            if ratingManager.showRatingPrompt {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            ratingManager.remindLater()
                        }

                    RatingPromptView(ratingManager: ratingManager)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: ratingManager.showRatingPrompt)
            }
        }
    }
}
