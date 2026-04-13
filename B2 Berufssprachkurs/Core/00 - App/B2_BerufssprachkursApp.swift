//
//  B2_BerufssprachkursApp.swift
//  B2 Berufssprachkurs
//
//  SwiftUI app entry point wiring scenes, persistence, and global environment objects.
//  Created: 24.03.26.
//

import SwiftUI
import SwiftData

// MARK: - App Entry

@main
struct B2_BerufssprachkursApp: App {
    // MARK: State & Environment

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearancePreference") private var appearancePreference: String = "System"
    @AppStorage("hasSeenWelcomeVideo") private var hasSeenWelcomeVideo: Bool = false

    // MARK: Persistence

    private let sharedModelContainer: ModelContainer

    // MARK: Initialization

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
    
    // MARK: Appearance

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
    
    // MARK: Scene

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenWelcomeVideo {
                    WelcomeVideoView(hasSeenWelcomeVideo: $hasSeenWelcomeVideo)
                } else {
                    MainView()
                }
            }
            .preferredColorScheme(colorScheme)
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
            switch newPhase {
            case .active:
                AppGroupQuickAddBridge.consumePendingQuickAddIfNeeded()
                NotificationManager.shared.cancelAllNotifications()
            case .background:
                NotificationManager.shared.scheduleRetentionNotification()
            default:
                break
            }
        }
    }
}
