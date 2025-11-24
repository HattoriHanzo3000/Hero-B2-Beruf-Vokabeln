//
//  TextSizeManager.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import Combine

@MainActor
class TextSizeManager: ObservableObject {
    static let shared = TextSizeManager()
    
    @Published var dynamicTypeSize: DynamicTypeSize = .large
    
    @AppStorage("textSizePreference") private var textSizePreference: String = "Large" {
        didSet {
            updateDynamicTypeSize()
        }
    }
    
    private init() {
        updateDynamicTypeSize()
    }
    
    private func updateDynamicTypeSize() {
        dynamicTypeSize = getDynamicTypeSize(for: textSizePreference)
    }
    
    private func getDynamicTypeSize(for preference: String) -> DynamicTypeSize {
        switch preference {
        case "Extra Small":
            return .xSmall
        case "Small":
            return .small
        case "Medium":
            return .medium
        case "Large":
            return .large
        case "Extra Large":
            return .xLarge
        case "XX Large":
            return .xxLarge
        case "XXX Large":
            return .xxxLarge
        default:
            return .large
        }
    }
}

