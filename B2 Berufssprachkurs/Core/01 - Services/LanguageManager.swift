//
//  LanguageManager.swift
//  B2 Berufssprachkurs
//
//  Controls active app language and localized bundle resolution.
//  Created: 24.11.25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Manager

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    private let appLanguageKey = "appLanguage"
    
    @Published var currentLanguage: String = "Deutsch" {
        didSet {
            updateLanguage()
        }
    }
    
    private var bundle: Bundle = .main
    
    // MARK: Lifecycle

    private init() {
        // Load initial language from UserDefaults; new installs default to German.
        currentLanguage = UserDefaults.standard.string(forKey: appLanguageKey) ?? "Deutsch"
        updateLanguage()
    }
    
    // MARK: Helpers

    private func updateLanguage() {
        // Map app language to locale code
        let localeCode: String
        switch currentLanguage {
        case "Deutsch":
            localeCode = "de"
        case "English":
            localeCode = "en"
        default:
            localeCode = "en"
        }
        
        // Find the localization bundle
        guard let path = Bundle.main.path(forResource: localeCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            self.bundle = .main
            return
        }
        
        self.bundle = bundle
    }
    
    // MARK: Public API

    func localizedBundle() -> Bundle {
        return bundle
    }
    
    func setLanguage(_ language: String) {
        UserDefaults.standard.set(language, forKey: appLanguageKey)
        DispatchQueue.main.async { [weak self] in
            self?.currentLanguage = language
        }
    }
}

