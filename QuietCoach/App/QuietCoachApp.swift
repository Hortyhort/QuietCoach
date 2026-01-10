// QuietCoachApp.swift
// QuietCoach
//
// The entry point. Clean, minimal, purposeful.
// Adapts to platform with native experiences.

import SwiftUI
import SwiftData
import TipKit
import OSLog

@main
struct QuietCoachApp: App {

    // MARK: - SwiftData Container

    let modelContainer: ModelContainer
    private let logger = Logger(subsystem: "com.quietcoach", category: "App")
    private let launchStartTime = CFAbsoluteTimeGetCurrent()

    // MARK: - Initialization

    init() {
        // Configure SwiftData with graceful fallback
        let schema = Schema([RehearsalSession.self])

        // Try persistent storage first
        if let container = Self.createPersistentContainer(schema: schema) {
            modelContainer = container
        } else {
            // Fallback to in-memory storage if persistent fails
            // This preserves app functionality even with storage issues
            Logger(subsystem: "com.quietcoach", category: "App")
                .error("Persistent storage failed, using in-memory fallback")

            let inMemoryConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [inMemoryConfig]
                )
            } catch {
                // Last resort: this should never happen with in-memory
                // but we still handle it gracefully
                Logger(subsystem: "com.quietcoach", category: "App")
                    .critical("All storage options failed: \(error.localizedDescription)")
                modelContainer = try! ModelContainer(for: schema)
            }
        }

        // Configure TipKit
        AppTipsConfiguration.configure()

        // Configure appearance (iOS/iPadOS only)
        #if os(iOS)
        configureAppearance()
        #endif

        // Apply file protection to existing recordings (security hardening)
        Task { @MainActor in
            FileStore.shared.applyFileProtectionToExistingRecordings()
        }
    }

    // MARK: - Scene

    var body: some Scene {
        // Main window
        WindowGroup {
            RootView()
                .modelContainer(modelContainer)
                .environment(FeatureGates.shared)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Track app launch time
                    let launchDuration = (CFAbsoluteTimeGetCurrent() - launchStartTime) * 1000
                    Logger(subsystem: "com.quietcoach", category: "Performance")
                        .info("App launch completed in \(String(format: "%.0f", launchDuration))ms")
                }
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 700)
        .commands {
            // Custom commands for macOS
            CommandGroup(replacing: .newItem) {
                Button("New Practice Session") {
                    // Open new practice session
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .sidebar) {
                Button("Toggle Recording") {
                    // Toggle recording
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Pause/Resume") {
                    // Pause or resume
                }
                .keyboardShortcut(.space, modifiers: [])
            }
        }
        #endif

        // macOS Menu Bar Extra
        #if os(macOS)
        MenuBarScene()
        #endif

        // visionOS Settings
        #if os(visionOS)
        Settings {
            SettingsView()
                .environment(FeatureGates.shared)
        }
        #endif
    }

    // MARK: - Appearance Configuration (iOS)

    #if os(iOS)
    private func configureAppearance() {
        // Prepare haptics
        Haptics.prepareAll()

        // Configure navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.black
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // Configure tab bar appearance (for future use)
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.black

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    #endif

    // MARK: - Container Factory

    /// Attempts to create a persistent ModelContainer, returns nil on failure
    private static func createPersistentContainer(schema: Schema) -> ModelContainer? {
        // Try CloudKit-enabled configuration first
        if let cloudContainer = createCloudKitContainer(schema: schema) {
            Logger(subsystem: "com.quietcoach", category: "App")
                .info("Using CloudKit-enabled container")
            return cloudContainer
        }

        // Fallback to local-only storage
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            Logger(subsystem: "com.quietcoach", category: "App")
                .info("Using local-only container")
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            Logger(subsystem: "com.quietcoach", category: "App")
                .error("Failed to create persistent container: \(error.localizedDescription)")
            return nil
        }
    }

    /// Attempts to create a CloudKit-enabled container
    private static func createCloudKitContainer(schema: Schema) -> ModelContainer? {
        #if !targetEnvironment(simulator)
        // CloudKit requires a real device and iCloud account
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.quietcoach")
        )
        do {
            return try ModelContainer(
                for: schema,
                configurations: [cloudConfig]
            )
        } catch {
            Logger(subsystem: "com.quietcoach", category: "App")
                .warning("CloudKit container failed, falling back to local: \(error.localizedDescription)")
            return nil
        }
        #else
        // Simulator doesn't support CloudKit sync well
        Logger(subsystem: "com.quietcoach", category: "App")
            .info("Simulator detected, skipping CloudKit")
        return nil
        #endif
    }
}
