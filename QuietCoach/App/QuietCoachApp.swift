// QuietCoachApp.swift
// QuietCoach
//
// The entry point. Clean, minimal, purposeful.
// Adapts to platform with native experiences.

import SwiftUI
import SwiftData
import TipKit

@main
struct QuietCoachApp: App {

    // MARK: - SwiftData Container

    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        // Configure SwiftData
        do {
            let schema = Schema([RehearsalSession.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }

        // Configure TipKit
        AppTipsConfiguration.configure()

        // Configure appearance (iOS/iPadOS only)
        #if os(iOS)
        configureAppearance()
        #endif
    }

    // MARK: - Scene

    var body: some Scene {
        // Main window
        WindowGroup {
            RootView()
                .modelContainer(modelContainer)
                .environment(FeatureGates.shared)
                .preferredColorScheme(.dark)
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
}
