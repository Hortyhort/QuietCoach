// AppIntents.swift
// QuietCoach
//
// Siri and Shortcuts integration. Practice with your voice.

import AppIntents
import SwiftUI

// MARK: - Scenario Entity

/// Makes Scenario available in Shortcuts
struct ScenarioEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Scenario")

    static let defaultQuery = ScenarioQuery()

    var id: String
    var title: String
    var subtitle: String
    var icon: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(subtitle)",
            image: .init(systemName: icon)
        )
    }

    init(from scenario: Scenario) {
        self.id = scenario.id
        self.title = scenario.title
        self.subtitle = scenario.subtitle
        self.icon = scenario.icon
    }
}

// MARK: - Scenario Query

struct ScenarioQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ScenarioEntity] {
        Scenario.allScenarios
            .filter { identifiers.contains($0.id) }
            .map { ScenarioEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [ScenarioEntity] {
        // Return free scenarios as suggestions
        Scenario.allScenarios
            .filter { !$0.isPro }
            .map { ScenarioEntity(from: $0) }
    }

    func defaultResult() async -> ScenarioEntity? {
        // Default to "Set a Boundary"
        Scenario.allScenarios.first.map { ScenarioEntity(from: $0) }
    }
}

// MARK: - Start Rehearsal Intent

/// "Hey Siri, practice a conversation with Quiet Coach"
struct StartRehearsalIntent: AppIntent {
    static let title: LocalizedStringResource = "Start a Rehearsal"

    static let description: IntentDescription = IntentDescription(
        "Start a rehearsal for a conversation scenario",
        categoryName: "Practice"
    )

    @Parameter(title: "Scenario", description: "The conversation scenario to practice")
    var scenario: ScenarioEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Start a rehearsal for \(\.$scenario)")
    }

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        // The app will open and the scenario selection will be handled
        // by the navigation system in RootView
        if let scenarioEntity = scenario {
            // Store the scenario ID for the app to pick up
            UserDefaults.standard.set(scenarioEntity.id, forKey: "pendingScenarioId")
        }
        return .result()
    }
}

// MARK: - Check Progress Intent

/// "Hey Siri, review my rehearsals"
struct CheckProgressIntent: AppIntent {
    static let title: LocalizedStringResource = "Review Rehearsals"

    static let description: IntentDescription = IntentDescription(
        "Open your recent rehearsals",
        categoryName: "Review"
    )

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        // Open the app and route to history
        UserDefaults.standard.set("history", forKey: "pendingRoute")
        return .result()
    }
}

// MARK: - App Shortcuts Provider

struct QuietCoachShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRehearsalIntent(),
            phrases: [
                "Start a rehearsal with \(.applicationName)",
                "Help me rehearse with \(.applicationName)",
                "Rehearse a conversation with \(.applicationName)",
                "I need to practice a hard conversation with \(.applicationName)",
                "Start \(\.$scenario) with \(.applicationName)"
            ],
            shortTitle: "Rehearse",
            systemImageName: "waveform"
        )

        AppShortcut(
            intent: CheckProgressIntent(),
            phrases: [
                "Review my rehearsals with \(.applicationName)",
                "Show recent rehearsals in \(.applicationName)",
                "Open rehearsal history in \(.applicationName)"
            ],
            shortTitle: "Review",
            systemImageName: "clock.arrow.circlepath"
        )

        AppShortcut(
            intent: QuietCoachFocusFilter(),
            phrases: [
                "Configure \(.applicationName) focus settings",
                "Set up \(.applicationName) for this focus"
            ],
            shortTitle: "Focus Settings",
            systemImageName: "moon.fill"
        )
    }
}
