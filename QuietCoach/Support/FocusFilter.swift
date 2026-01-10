// FocusFilter.swift
// QuietCoach
//
// Focus Filter integration for context-aware behavior.
// Users can customize app behavior per Focus mode.

import AppIntents
import SwiftUI
import OSLog

// MARK: - Focus Filter Intent

/// Focus Filter that users can configure in Settings > Focus
@available(iOS 16.0, *)
struct QuietCoachFocusFilter: SetFocusFilterIntent {

    // MARK: - Metadata

    nonisolated static let title: LocalizedStringResource = "Quiet Coach Focus Settings"
    nonisolated static let description = IntentDescription(
        "Configure Quiet Coach behavior for this Focus mode",
        categoryName: "Practice Settings"
    )

    // MARK: - Parameters

    /// Whether to show practice reminders in this Focus
    @Parameter(title: "Show Practice Reminders", default: true)
    var showReminders: Bool

    /// Whether to allow sounds in this Focus
    @Parameter(title: "Allow Sounds", default: true)
    var allowSounds: Bool

    /// Whether to suggest practice scenarios
    @Parameter(title: "Suggest Practice Sessions", default: true)
    var suggestPractice: Bool

    /// Filter to specific categories
    @Parameter(title: "Scenario Categories")
    var categories: [FocusScenarioCategory]?

    // MARK: - Display Representation

    var displayRepresentation: DisplayRepresentation {
        var summary = "Quiet Coach: "
        var details: [String] = []

        if !showReminders {
            details.append("Reminders off")
        }
        if !allowSounds {
            details.append("Sounds off")
        }
        if !suggestPractice {
            details.append("No suggestions")
        }
        if let categories = categories, !categories.isEmpty {
            details.append("\(categories.count) categories")
        }

        if details.isEmpty {
            summary += "Default settings"
        } else {
            summary += details.joined(separator: ", ")
        }

        return DisplayRepresentation(stringLiteral: summary)
    }

    // MARK: - Perform

    @MainActor
    func perform() async throws -> some IntentResult {
        // Store the filter settings
        FocusFilterManager.shared.applyFilter(
            showReminders: showReminders,
            allowSounds: allowSounds,
            suggestPractice: suggestPractice,
            categories: categories?.compactMap { Scenario.Category(rawValue: $0.rawValue) }
        )

        return .result()
    }
}

// MARK: - Focus Scenario Category (App Entity)

/// App Entity representing scenario categories for Focus filters
@available(iOS 16.0, *)
struct FocusScenarioCategory: AppEntity {

    // MARK: - Properties

    var id: String
    var rawValue: String

    // MARK: - Type Metadata

    nonisolated static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Scenario Category"
    )

    nonisolated static let defaultQuery = FocusScenarioCategoryQuery()

    // MARK: - Display

    var displayRepresentation: DisplayRepresentation {
        switch rawValue {
        case "Boundaries":
            return DisplayRepresentation(
                title: "Boundaries",
                subtitle: "Setting limits with confidence",
                image: .init(systemName: "hand.raised.fill")
            )
        case "Career":
            return DisplayRepresentation(
                title: "Career",
                subtitle: "Professional conversations",
                image: .init(systemName: "briefcase.fill")
            )
        case "Relationships":
            return DisplayRepresentation(
                title: "Relationships",
                subtitle: "Personal connections",
                image: .init(systemName: "heart.fill")
            )
        case "Difficult":
            return DisplayRepresentation(
                title: "Difficult",
                subtitle: "Challenging conversations",
                image: .init(systemName: "exclamationmark.bubble.fill")
            )
        default:
            return DisplayRepresentation(title: LocalizedStringResource(stringLiteral: rawValue))
        }
    }

    // MARK: - Static Categories

    static let boundaries = FocusScenarioCategory(id: "boundaries", rawValue: "Boundaries")
    static let career = FocusScenarioCategory(id: "career", rawValue: "Career")
    static let relationships = FocusScenarioCategory(id: "relationships", rawValue: "Relationships")
    static let difficult = FocusScenarioCategory(id: "difficult", rawValue: "Difficult")

    nonisolated static let allCategories: [FocusScenarioCategory] = [
        .boundaries, .career, .relationships, .difficult
    ]
}

// MARK: - Focus Scenario Category Query

@available(iOS 16.0, *)
struct FocusScenarioCategoryQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FocusScenarioCategory] {
        FocusScenarioCategory.allCategories.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [FocusScenarioCategory] {
        FocusScenarioCategory.allCategories
    }
}

// MARK: - Focus Filter Manager

/// Manages Focus Filter state and applies settings
@MainActor
final class FocusFilterManager: ObservableObject {

    // MARK: - Singleton

    static let shared = FocusFilterManager()

    // MARK: - Published State

    @Published private(set) var showReminders: Bool = true
    @Published private(set) var allowSounds: Bool = true
    @Published private(set) var suggestPractice: Bool = true
    @Published private(set) var activeCategories: [Scenario.Category]?

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.quietcoach", category: "FocusFilter")

    // MARK: - Initialization

    private init() {
        loadDefaults()
    }

    // MARK: - Apply Filter

    /// Apply Focus Filter settings
    func applyFilter(
        showReminders: Bool,
        allowSounds: Bool,
        suggestPractice: Bool,
        categories: [Scenario.Category]?
    ) {
        self.showReminders = showReminders
        self.allowSounds = allowSounds
        self.suggestPractice = suggestPractice
        self.activeCategories = categories

        // Update UserDefaults for persistence
        UserDefaults.standard.set(showReminders, forKey: "focusFilter.showReminders")
        UserDefaults.standard.set(allowSounds, forKey: "focusFilter.allowSounds")
        UserDefaults.standard.set(suggestPractice, forKey: "focusFilter.suggestPractice")

        if let categories = categories {
            UserDefaults.standard.set(categories.map { $0.rawValue }, forKey: "focusFilter.categories")
        } else {
            UserDefaults.standard.removeObject(forKey: "focusFilter.categories")
        }

        logger.info("Applied Focus Filter: reminders=\(showReminders), sounds=\(allowSounds), suggest=\(suggestPractice)")

        // Apply sound settings immediately
        if !allowSounds {
            UserDefaults.standard.set(false, forKey: Constants.SettingsKeys.soundsEnabled)
        }
    }

    /// Reset to default settings (when no Focus is active)
    func resetToDefaults() {
        showReminders = true
        allowSounds = true
        suggestPractice = true
        activeCategories = nil

        // Remove stored values
        UserDefaults.standard.removeObject(forKey: "focusFilter.showReminders")
        UserDefaults.standard.removeObject(forKey: "focusFilter.allowSounds")
        UserDefaults.standard.removeObject(forKey: "focusFilter.suggestPractice")
        UserDefaults.standard.removeObject(forKey: "focusFilter.categories")

        logger.info("Reset Focus Filter to defaults")
    }

    // MARK: - Load Defaults

    private func loadDefaults() {
        if UserDefaults.standard.object(forKey: "focusFilter.showReminders") != nil {
            showReminders = UserDefaults.standard.bool(forKey: "focusFilter.showReminders")
        }
        if UserDefaults.standard.object(forKey: "focusFilter.allowSounds") != nil {
            allowSounds = UserDefaults.standard.bool(forKey: "focusFilter.allowSounds")
        }
        if UserDefaults.standard.object(forKey: "focusFilter.suggestPractice") != nil {
            suggestPractice = UserDefaults.standard.bool(forKey: "focusFilter.suggestPractice")
        }
        if let categoryStrings = UserDefaults.standard.stringArray(forKey: "focusFilter.categories") {
            activeCategories = categoryStrings.compactMap { Scenario.Category(rawValue: $0) }
        }
    }

    // MARK: - Filtered Scenarios

    /// Get scenarios filtered by current Focus settings
    func filteredScenarios() -> [Scenario] {
        if let categories = activeCategories, !categories.isEmpty {
            return Scenario.allScenarios.filter { categories.contains($0.category) }
        }
        return Scenario.allScenarios
    }

    /// Check if reminders should be shown
    var shouldShowReminders: Bool {
        showReminders
    }

    /// Check if sounds are allowed
    var areSoundsAllowed: Bool {
        allowSounds && Constants.Sounds.enabled
    }

    /// Check if practice should be suggested
    var shouldSuggestPractice: Bool {
        suggestPractice
    }
}

