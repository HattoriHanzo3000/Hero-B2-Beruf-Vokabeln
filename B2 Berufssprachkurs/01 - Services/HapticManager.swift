//
//  HapticManager.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import UIKit

@MainActor
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
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
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

