//
//  B2_BerufssprachkursApp.swift
//  B2 Berufssprachkurs
//
//  Created by Ildar on 18.11.25.
//

import SwiftUI
import SwiftData

@main
struct B2_BerufssprachkursApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearancePreference") private var appearancePreference: String = "System"
    @AppStorage("hasSeenWelcomeVideo") private var hasSeenWelcomeVideo: Bool = false

    private let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([
            WordProgress.self,
            CustomWordEntry.self,
            StudySelectionState.self,
            FavoriteWord.self,
            SpacedRepetitionRecord.self
        ])
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
                    MainView()
                }
            }
            // Apply appearance preference (Light/Dark/System)
            .preferredColorScheme(colorScheme)
            // Portrait: `AppDelegate.orientationLock` (default `.portrait`) + `supportedInterfaceOrientationsFor`
            .environmentObject(LanguageManager.shared)
            .environmentObject(AppearanceManager.shared)
            .environmentObject(AppDeepLinkRouter.shared)
            .onOpenURL { url in
                AppDeepLinkRouter.shared.handle(url: url)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                AppGroupQuickAddBridge.consumePendingQuickAddIfNeeded()
            }
            .task {
                MigrationManager.runTranslationsImportIfNeeded(
                    context: sharedModelContainer.mainContext
                )
            }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            // Supportive Retention System using Local Notifications
            switch newPhase {
            case .active:
                AppGroupQuickAddBridge.consumePendingQuickAddIfNeeded()
                // Cancel pending notifications and clear badge when the user is active
                NotificationManager.shared.cancelAllNotifications()
            case .background:
                // Schedule a gentle reminder for 3 days from now if they don't return
                NotificationManager.shared.scheduleRetentionNotification()
            default:
                break
            }
        }
    }
}
