//
//  NotificationManager.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 07.04.26.
//

import Foundation
import UserNotifications
import SwiftUI

/// Manages local notifications to encourage user engagement.
/// Aligns with Apple's HIG by providing gentle, supportive reminders.
class NotificationManager {
    static let shared = NotificationManager()
    
    /// Tracks if we have already presented the system notification permission alert.
    /// Following Apple's HIG, we want to ask for permission only after the user experiences value.
    @AppStorage("hasRequestedNotificationPermission") private var hasRequestedPermission = false
    @AppStorage("notificationSoftPromptAttemptCount") private var softPromptAttemptCount = 0
    @AppStorage("notificationSoftPromptNeverAskAgain") private var softPromptNeverAskAgain = false
    @AppStorage("notificationSoftPromptNextEligibleAt") private var softPromptNextEligibleAt: Double = 0
    
    private let notificationId = "retention_notification"
    private let dayInSeconds: TimeInterval = 24 * 3600
    
    private init() {}
    
    /// Requests user permission to show local notifications.
    /// Only presents the system alert if it hasn't been shown before.
    func requestAuthorization() {
        // Ensure we only ask once to avoid annoying the user
        guard !hasRequestedPermission else { return }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            Task { @MainActor in
                // Set the flag to true regardless of whether they granted or denied,
                // as the system alert can only be shown once.
                self.hasRequestedPermission = true
                
                if let error = error {
                    print("Error requesting notification authorization: \(error)")
                }
            }
        }
    }

    /// Determines whether the in-app soft prompt should be shown.
    /// We only show it before the first system prompt (`.notDetermined`), honoring cooldown and opt-out rules.
    func shouldPresentSoftPrompt(completion: @escaping (Bool) -> Void) {
        guard !softPromptNeverAskAgain else {
            completion(false)
            return
        }

        guard softPromptAttemptCount < 3 else {
            completion(false)
            return
        }

        let now = Date().timeIntervalSince1970
        if softPromptAttemptCount > 0, now < softPromptNextEligibleAt {
            completion(false)
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // Only show the soft prompt before iOS has asked.
            completion(settings.authorizationStatus == .notDetermined)
        }
    }

    /// User selected the positive action from the in-app soft prompt.
    /// This is the only path that triggers the iOS system permission alert.
    func handleSoftPromptAllow() {
        requestAuthorization()
    }

    /// User selected "Ask me later".
    /// Attempt 1 -> 7 days, attempt 2 -> 21 days, attempt 3 -> stop asking.
    func handleSoftPromptAskMeLater() {
        softPromptAttemptCount += 1

        switch softPromptAttemptCount {
        case 1:
            softPromptNextEligibleAt = Date().addingTimeInterval(7 * dayInSeconds).timeIntervalSince1970
        case 2:
            softPromptNextEligibleAt = Date().addingTimeInterval(21 * dayInSeconds).timeIntervalSince1970
        default:
            softPromptNeverAskAgain = true
            softPromptNextEligibleAt = 0
        }
    }

    /// User selected "No, thanks" from the in-app soft prompt.
    /// We stop showing soft prompts permanently.
    func handleSoftPromptNoThanks() {
        softPromptNeverAskAgain = true
        softPromptNextEligibleAt = 0
    }
    
    /// Schedules a supportive notification for 72 hours (3 days) in the future.
    /// This helps maintain retention without being intrusive.
    func scheduleRetentionNotification() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = settings.authorizationStatus
            let canSchedule = status == .authorized || status == .provisional || status == .ephemeral
            guard canSchedule else { return }

            let content = UNMutableNotificationContent()
            content.title = Localizable.string(Localizable.notificationRetentionTitle)
            content.body = Localizable.string(Localizable.notificationRetentionBody)
            content.sound = .default

            // 3 days = 72 hours = 72 * 3600 seconds
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 72 * 3600, repeats: false)

            let request = UNNotificationRequest(
                identifier: self.notificationId,
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling retention notification: \(error)")
                }
            }
        }
    }
    
    /// Cancels all pending notifications to ensure the user isn't reminded while actively using the app.
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // Reset the badge count when the app is active
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
