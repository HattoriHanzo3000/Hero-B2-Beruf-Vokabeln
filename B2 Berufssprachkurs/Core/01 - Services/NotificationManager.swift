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
    
    private let notificationId = "retention_notification"
    
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
    
    /// Schedules a supportive notification for 72 hours (3 days) in the future.
    /// This helps maintain retention without being intrusive.
    func scheduleRetentionNotification() {
        let content = UNMutableNotificationContent()
        content.title = Localizable.string(Localizable.notificationRetentionTitle)
        content.body = Localizable.string(Localizable.notificationRetentionBody)
        content.sound = .default
        
        // 3 days = 72 hours = 72 * 3600 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 72 * 3600, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling retention notification: \(error)")
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
