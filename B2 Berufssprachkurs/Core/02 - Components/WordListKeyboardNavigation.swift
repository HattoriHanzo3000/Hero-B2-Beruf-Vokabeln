//
//  WordListKeyboardNavigation.swift
//  B2 Berufssprachkurs
//
//  ObservableObject so `TranslationTextField` rows only refresh when prev/next enabled flags
//  change, not on every parent `body` evaluation (unlike a fresh Environment struct + closures).
//

import Combine
import SwiftUI
import UIKit

/// How much of the key window is covered by the keyboard (matches end frame from `keyboardWillChangeFrame`).
func wordListKeyboardOverlapHeight(frameEnd: CGRect) -> CGFloat {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
    else {
        return max(0, UIScreen.main.bounds.height - frameEnd.minY)
    }
    let frameInWindow = window.convert(frameEnd, from: nil)
    return max(0, window.bounds.maxY - frameInWindow.minY)
}

/// Tracks keyboard overlap so list scroll margins and pinned bottom controls (e.g. Üben) stay in sync with UIKit.
/// Observers use `queue: .main`; do not create off-main.
final class WordListKeyboardMetrics: ObservableObject {
    @Published var bottomOverlap: CGFloat = 0
    private var observationTokens: [NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default
        observationTokens.append(center.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else { return }
            
            // Defer update to avoid "Publishing changes from within view updates is not allowed"
            DispatchQueue.main.async {
                self.bottomOverlap = wordListKeyboardOverlapHeight(frameEnd: frame)
            }
        })
        observationTokens.append(center.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Defer update to avoid "Publishing changes from within view updates is not allowed"
            DispatchQueue.main.async {
                self?.bottomOverlap = 0
            }
        })
    }

    deinit {
        observationTokens.forEach(NotificationCenter.default.removeObserver)
    }
}

@MainActor
final class WordListKeyboardNavBridge: ObservableObject {
    @Published private(set) var canGoToPrevious = false
    @Published private(set) var canGoToNext = false

    var onPrevious: () -> Void = {}
    var onNext: () -> Void = {}
    var onDismiss: () -> Void = {}

    func attachHandlers(onPrevious: @escaping () -> Void, onNext: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onDismiss = onDismiss
    }

    func syncCanNavigate(canPrevious: Bool, canNext: Bool) {
        if canGoToPrevious != canPrevious {
            canGoToPrevious = canPrevious
        }
        if canGoToNext != canNext {
            canGoToNext = canNext
        }
    }
}
