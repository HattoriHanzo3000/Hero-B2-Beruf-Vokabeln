//
//  HapticManager.swift
//  B2 Berufssprachkurs
//
//  Central helper for gated haptic feedback across the app.
//  Created: 19.11.25.
//

import UIKit

// MARK: - Manager

@MainActor
class HapticManager {
    static let shared = HapticManager()
    
    private let userDefaults = UserDefaults.standard
    private let hapticFeedbackEnabledKey = "hapticFeedbackEnabled"
    
    private init() {}
    
    private var isHapticFeedbackEnabled: Bool {
        // Default to true if the key doesn't exist
        if userDefaults.object(forKey: hapticFeedbackEnabledKey) == nil {
            return true
        }
        return userDefaults.bool(forKey: hapticFeedbackEnabledKey)
    }
    
    // MARK: - Impact Feedback
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isHapticFeedbackEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func lightImpact() {
        impact(style: .light)
    }
    
    func mediumImpact() {
        impact(style: .medium)
    }
    
    func heavyImpact() {
        impact(style: .heavy)
    }
    
    func softImpact() {
        if #available(iOS 13.0, *) {
            impact(style: .soft)
        } else {
            impact(style: .medium)
        }
    }
    
    func rigidImpact() {
        if #available(iOS 13.0, *) {
            impact(style: .rigid)
        } else {
            impact(style: .heavy)
        }
    }
    
    // MARK: - Notification Feedback
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isHapticFeedbackEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func success() {
        notification(type: .success)
    }
    
    func warning() {
        notification(type: .warning)
    }
    
    func error() {
        notification(type: .error)
    }
    
    // MARK: - Selection Feedback
    
    func selection() {
        guard isHapticFeedbackEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

