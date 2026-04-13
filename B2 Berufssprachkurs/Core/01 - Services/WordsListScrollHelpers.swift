//
//  WordsListScrollHelpers.swift
//  B2 Berufssprachkurs
//
//  Reusable scrolling helpers for word-list focus and deep links.
//  Created: 05.04.26.
//

import SwiftUI

// MARK: - WordsListScrollHelpers

enum WordsListScrollHelpers {
    /// After opening from search, scrolls the target row to the **center** with one animation after a short layout yield.
    @MainActor
    static func startDeepLinkCenterTask(
        replacing existing: inout Task<Void, Never>?,
        proxy: ScrollViewProxy,
        scrollToWordIdOnAppear: String?,
        listUIState: LearningListsUIState,
        sectionId: String,
        wordIdsInList: Set<String>,
        accessibilityReduceMotion: Bool,
    ) {
        let fromParam = scrollToWordIdOnAppear
        if let id = fromParam {
            listUIState.setWordsListScrollWordId(id, for: sectionId)
        }
        let wordId = fromParam ?? listUIState.wordsListScrollWordId(for: sectionId)
        guard let wordId, wordIdsInList.contains(wordId) else { return }

        let deepLink = fromParam != nil
        let sid = sectionId
        let targetId = wordId

        existing?.cancel()
        existing = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 72_000_000)
            guard !Task.isCancelled else { return }
            if accessibilityReduceMotion {
                proxy.scrollTo(targetId, anchor: .center)
            } else {
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo(targetId, anchor: .center)
                }
            }
            if deepLink {
                try? await Task.sleep(nanoseconds: 520_000_000)
                guard !Task.isCancelled else { return }
                listUIState.setWordsListScrollWordId(nil, for: sid)
            }
        }
    }

    /// Scrolls the active word row into the visible area above the keyboard.
    static func scrollFocusedRowForKeyboard(
        proxy: ScrollViewProxy,
        wordId: String,
        keyboardBottomOverlap: CGFloat,
        delays: [TimeInterval]
    ) {
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let overlap = keyboardBottomOverlap
                let anchor: UnitPoint
                if overlap > 50 {
                    let y = min(0.32, 0.1 + (overlap / 950))
                    anchor = UnitPoint(x: 0.5, y: y)
                } else {
                    anchor = UnitPoint(x: 0.5, y: 0.5)
                }
                withAnimation(.easeInOut(duration: 0.28)) {
                    proxy.scrollTo(wordId, anchor: anchor)
                }
            }
        }
    }
}
