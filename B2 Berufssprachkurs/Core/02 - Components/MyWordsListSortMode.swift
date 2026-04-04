//
//  MyWordsListSortMode.swift
//  B2 Berufssprachkurs
//
//  Sort mode for the My Words list (persisted via AppStorage).
//

import Foundation

enum MyWordsListSortMode: String, CaseIterable, Identifiable {
    case manual
    case nameAscending
    case nameDescending
    case dateAscending
    case dateDescending

    var id: String { rawValue }

    static let appStorageKey = "myWordsListSortModeRaw"

    /// Handles legacy single-option values saved before direction submenus existed.
    static func resolved(from stored: String) -> MyWordsListSortMode {
        switch stored {
        case MyWordsListSortMode.manual.rawValue: return .manual
        case MyWordsListSortMode.nameAscending.rawValue, "name": return .nameAscending
        case MyWordsListSortMode.nameDescending.rawValue: return .nameDescending
        case MyWordsListSortMode.dateAscending.rawValue: return .dateAscending
        case MyWordsListSortMode.dateDescending.rawValue, "dateAdded": return .dateDescending
        default: return .manual
        }
    }

    /// Rewrites legacy `name` / `dateAdded` tokens to explicit stored values (for `@AppStorage`).
    static func migratedAppStorageValue(from raw: String) -> String {
        switch raw {
        case "name":
            return MyWordsListSortMode.nameAscending.rawValue
        case "dateAdded":
            return MyWordsListSortMode.dateDescending.rawValue
        default:
            return raw
        }
    }

    func sortedEntries(from entries: [CustomWordEntry]) -> [CustomWordEntry] {
        switch self {
        case .manual:
            return entries
        case .nameAscending:
            return entries.sorted {
                $0.german.trimmingCharacters(in: .whitespacesAndNewlines)
                    .localizedCaseInsensitiveCompare($1.german.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedAscending
            }
        case .nameDescending:
            return entries.sorted {
                $0.german.trimmingCharacters(in: .whitespacesAndNewlines)
                    .localizedCaseInsensitiveCompare($1.german.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedDescending
            }
        case .dateAscending:
            return entries.sorted { $0.createdAt < $1.createdAt }
        case .dateDescending:
            return entries.sorted { $0.createdAt > $1.createdAt }
        }
    }

    /// Subtitle under “Sort by” in the overflow menu (current sort selection).
    var sortOverflowMenuSubtitle: String {
        switch self {
        case .manual:
            Localizable.string(Localizable.myWordsSortManual)
        case .nameAscending:
            "\(Localizable.string(Localizable.myWordsSortTitle)) · \(Localizable.string(Localizable.myWordsSortAscending))"
        case .nameDescending:
            "\(Localizable.string(Localizable.myWordsSortTitle)) · \(Localizable.string(Localizable.myWordsSortDescending))"
        case .dateAscending:
            "\(Localizable.string(Localizable.myWordsSortCreationDate)) · \(Localizable.string(Localizable.myWordsSortDateOldestFirst))"
        case .dateDescending:
            "\(Localizable.string(Localizable.myWordsSortCreationDate)) · \(Localizable.string(Localizable.myWordsSortDateNewestFirst))"
        }
    }
}
