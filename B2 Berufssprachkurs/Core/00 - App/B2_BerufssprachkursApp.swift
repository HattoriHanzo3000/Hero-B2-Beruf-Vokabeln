//
//  B2_BerufssprachkursApp.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import SwiftData

// View modifier to lock orientation to portrait
struct PortraitOrientationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                AppDelegate.orientationLock = .portrait
            }
    }
}

extension View {
    func portraitOrientation() -> some View {
        self.modifier(PortraitOrientationModifier())
    }
}

@main
struct B2_BerufssprachkursApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("appearancePreference") private var appearancePreference: String = "System"
    @AppStorage("hasSeenWelcomeVideo") private var hasSeenWelcomeVideo: Bool = false

    private let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([WordProgress.self])
        let iCloudSyncEnabled =
            UserDefaults.standard.object(forKey: MigrationManager.iCloudSyncEnabledKey) as? Bool ?? true
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase =
            iCloudSyncEnabled ? .automatic : .none
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKitDatabase
        )
        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch appearancePreference {
        case "Light":
            return .light
        case "Dark":
            return .dark
        case "System":
            return nil // nil means use system default
        default:
            return nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenWelcomeVideo {
                    WelcomeVideoView(hasSeenWelcomeVideo: $hasSeenWelcomeVideo)
                } else {
                    MainTabView()
                }
            }
            // Apply appearance preference (Light/Dark/System)
            .preferredColorScheme(colorScheme)
            // Lock orientation to portrait only
            .portraitOrientation()
            .environmentObject(LanguageManager.shared)
            .environmentObject(AppearanceManager.shared)
            .task {
                MigrationManager.runTranslationsImportIfNeeded(
                    context: sharedModelContainer.mainContext
                )
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
