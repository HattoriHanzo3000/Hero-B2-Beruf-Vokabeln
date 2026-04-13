//
//  SpacedRepetitionNotifications.swift
//  B2 Berufssprachkurs
//
//  Schedules spaced-repetition reminder notifications for due items.
//  Created: 05.04.26.
//

import Foundation

// MARK: - Notification

extension Notification.Name {
    /// Posted when spaced-repetition data is saved (see ``SpacedRepetitionService``).
    static let spacedRepetitionUpdated = Notification.Name("SpacedRepetitionUpdated")
}
