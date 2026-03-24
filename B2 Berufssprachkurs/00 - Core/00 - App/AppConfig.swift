//
//  AppConfig.swift
//  B2 Berufssprachkurs
//
//  Secure configuration for API keys and sensitive data
//  This file should be added to .gitignore to prevent committing API keys
//

import Foundation

/// Secure configuration manager for API keys and sensitive app data
/// 
/// This class provides a centralized way to manage API keys securely.
/// For production, consider using:
/// - Environment variables
/// - Xcode build configuration files
/// - Secure keychain storage
/// - CI/CD secrets management
///
/// **Security Best Practices:**
/// - Never commit API keys to version control
/// - Use different keys for development and production
/// - Rotate keys regularly
/// - Use environment-specific configurations
enum AppConfig {
    
    // MARK: - RevenueCat Configuration
    
    /// RevenueCat Public API Key
    /// 
    /// Get from: https://app.revenuecat.com → Your Project → API Keys
    /// 
    /// **Important:**
    /// - Use test/sandbox key for development
    /// - Use production key for release builds
    /// - Never commit production keys to version control
    static var revenueCatAPIKey: String {
        // Option 1: Read from Info.plist (recommended for production)
        if let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
           !key.isEmpty {
            return key
        }
        
        // Option 2: Read from environment variable (for CI/CD)
        if let key = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"],
           !key.isEmpty {
            return key
        }
        
        // Option 3: Hardcoded fallback (for development only)
        // 
        // ⚠️ IMPORTANT NOTES ABOUT API KEYS:
        // 
        // 1. RevenueCat Public API Keys (starting with "appl_" or "pk_") are MEANT to be in client code.
        //    They are NOT secret keys - they're public identifiers for your project.
        // 
        // 2. However, you may want separate keys for:
        //    - Development/Testing: Use test/sandbox environment
        //    - Production: Use production environment
        //    (RevenueCat may provide separate keys, or you might use the same key for both)
        //
        // 3. If RevenueCat gives you separate test/prod keys, use them here.
        //    If they give you one key that works for both, that's fine too.
        //
        // 4. The real security concern is using the RIGHT environment, not hiding the key.
        //    RevenueCat handles security server-side.
        //
        // 5. For maximum security, move keys to Info.plist (see INTEGRATION_CHECKLIST.md)
        //
        // Use production key for both DEBUG and RELEASE
        // Test Store is optional - using production key is simpler and still safe for testing
        // Apple handles sandbox purchases automatically, so testing is safe even with production key
        return "appl_rcEmwNiUYUgSBkoXePHgjfKFjcI"
    }
    
    // MARK: - Validation
    
    /// Validates that API keys are configured (not placeholder values)
    static func validateConfiguration() -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        // Check RevenueCat API key
        let revenueCatKey = revenueCatAPIKey
        if revenueCatKey.contains("YOUR_") || revenueCatKey.isEmpty {
            errors.append("RevenueCat API key is not configured")
        }
        
        return (errors.isEmpty, errors)
    }
    
    // MARK: - Configuration Source
    
    /// Returns the source of configuration (for debugging)
    static func configurationSource() -> [String: String] {
        var source: [String: String] = [:]
        
        // Check RevenueCat
        if Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String != nil {
            source["RevenueCat"] = "Info.plist"
        } else if ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"] != nil {
            source["RevenueCat"] = "Environment Variable"
        } else {
            source["RevenueCat"] = "Hardcoded (Fallback)"
        }
        
        return source
    }
}
