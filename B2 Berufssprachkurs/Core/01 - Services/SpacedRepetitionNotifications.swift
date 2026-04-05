//
//  SpacedRepetitionNotifications.swift
//  B2 Berufssprachkurs
//

import Foundation

extension Notification.Name {
    /// Posted when spaced-repetition data is saved (see ``SpacedRepetitionService``).
    static let spacedRepetitionUpdated = Notification.Name("SpacedRepetitionUpdated")
}
