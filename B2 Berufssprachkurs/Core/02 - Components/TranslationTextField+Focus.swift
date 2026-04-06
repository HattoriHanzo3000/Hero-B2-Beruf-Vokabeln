//
//  TranslationTextField+Focus.swift
//  B2 Berufssprachkurs
//

import Foundation
import UIKit

final class TranslationFocusRetrier {
    private var session: UInt = 0
    private var scheduledSession: UInt?
    private let retryDelays: [TimeInterval] = [0.0, 0.05, 0.2, 0.45]
    private let resetDelay: TimeInterval = 0.5

    func cancel() {
        session &+= 1
        scheduledSession = nil
    }

    func request(
        shouldFocus: @escaping () -> Bool,
        becomeFirstResponder: @escaping () -> Void,
        isFirstResponder: @escaping () -> Bool
    ) {
        guard shouldFocus() else { return }
        if scheduledSession == session { return }
        scheduledSession = session

        let currentSession = session
        for delay in retryDelays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                guard currentSession == self.session else { return }
                guard shouldFocus() else { return }
                if !isFirstResponder() {
                    becomeFirstResponder()
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + resetDelay) { [weak self] in
            guard let self else { return }
            guard currentSession == self.session else { return }
            guard shouldFocus() else { return }
            if !isFirstResponder() {
                self.scheduledSession = nil
            }
        }
    }
}

extension TranslationTextField.Coordinator {
    func requestFirstResponderIfNeeded() {
        let wid = parent.wordId
        focusRetrier.request(
            shouldFocus: { [weak self] in
                guard let self else { return false }
                return self.parent.focusedWordId == wid
            },
            becomeFirstResponder: { [weak self] in
                guard let self, let tv = self.textView, tv.window != nil else { return }
                tv.becomeFirstResponder()
            },
            isFirstResponder: { [weak self] in
                self?.textView?.isFirstResponder == true
            }
        )
    }
}
