//
//  PlanDateFormatting.swift
//  B2 Berufssprachkurs
//

import Foundation

enum PlanDateFormatting {
    private static let deFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    private static let enFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    static func mediumDateString(_ date: Date, language: String) -> String {
        switch language {
        case "Deutsch":
            return deFormatter.string(from: date)
        default:
            return enFormatter.string(from: date)
        }
    }
}
