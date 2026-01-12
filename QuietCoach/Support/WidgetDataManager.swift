// WidgetDataManager.swift
// QuietCoach
//
// Manages shared data between the main app and widgets via App Groups.
// Updates widget content when session data changes.

import Foundation
import WidgetKit
import OSLog

@Observable
@MainActor
final class WidgetDataManager {

    // MARK: - Singleton

    static let shared = WidgetDataManager()

    // MARK: - App Group

    private static let appGroupID = "group.com.quietcoach"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupID) ?? .standard
    }

    private let logger = Logger(subsystem: "com.quietcoach", category: "WidgetData")

    // MARK: - Keys

    private enum Keys {
        // Last Session Widget
        static let lastScenarioTitle = "widget.lastScenarioTitle"
        static let lastOverallScore = "widget.lastOverallScore"
        static let lastSessionDate = "widget.lastSessionDate"

        // Quick Practice Widget
        static let pendingScenarioId = "pendingScenarioId"
        static let launchToQuickPractice = "launchToQuickPractice"

        // Recording State
        static let isCurrentlyRecording = "isCurrentlyRecording"
        static let toggleRecordingRequested = "toggleRecordingRequested"
        static let requestedRecordingState = "requestedRecordingState"
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Last Session Data

    /// Update last session widget data
    func updateLastSessionData(scenarioTitle: String, overallScore: Int, sessionDate: Date) {
        defaults.set(scenarioTitle, forKey: Keys.lastScenarioTitle)
        defaults.set(overallScore, forKey: Keys.lastOverallScore)
        defaults.set(sessionDate.timeIntervalSince1970, forKey: Keys.lastSessionDate)

        reloadWidgets(kind: "LastSessionWidget")
        logger.info("Updated last session: \(scenarioTitle), score: \(overallScore)")
    }

    /// Clear last session data
    func clearLastSessionData() {
        defaults.removeObject(forKey: Keys.lastScenarioTitle)
        defaults.removeObject(forKey: Keys.lastOverallScore)
        defaults.removeObject(forKey: Keys.lastSessionDate)

        reloadWidgets(kind: "LastSessionWidget")
    }

    // MARK: - Quick Practice Intent

    /// Check and consume pending scenario ID from widget
    func consumePendingScenarioId() -> String? {
        guard let scenarioId = defaults.string(forKey: Keys.pendingScenarioId),
              !scenarioId.isEmpty else {
            return nil
        }

        // Clear the pending ID
        defaults.removeObject(forKey: Keys.pendingScenarioId)

        // Track widget tap attribution
        Analytics.shared.widgetTapped(widgetType: "quick_practice", scenarioId: scenarioId)

        logger.info("Consumed pending scenario: \(scenarioId)")
        return scenarioId
    }

    /// Check if launched from quick practice
    func consumeLaunchToQuickPractice() -> Bool {
        let shouldLaunch = defaults.bool(forKey: Keys.launchToQuickPractice)
        if shouldLaunch {
            defaults.removeObject(forKey: Keys.launchToQuickPractice)
            logger.info("Consumed quick practice launch flag")
        }
        return shouldLaunch
    }

    // MARK: - Recording State (for Control Center)

    /// Update recording state for Control Center widget
    func updateRecordingState(isRecording: Bool) {
        defaults.set(isRecording, forKey: Keys.isCurrentlyRecording)

        #if os(iOS)
        if #available(iOS 18.0, *) {
            ControlCenter.shared.reloadAllControls()
        }
        #endif
    }

    /// Check if toggle recording was requested
    func consumeToggleRecordingRequest() -> Bool? {
        let wasRequested = defaults.bool(forKey: Keys.toggleRecordingRequested)
        guard wasRequested else { return nil }

        let requestedState = defaults.bool(forKey: Keys.requestedRecordingState)

        // Clear the request
        defaults.removeObject(forKey: Keys.toggleRecordingRequested)
        defaults.removeObject(forKey: Keys.requestedRecordingState)

        logger.info("Consumed toggle recording request: \(requestedState)")
        return requestedState
    }

    // MARK: - Widget Reload

    /// Reload specific widget
    private func reloadWidgets(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    /// Reload all widgets
    func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        logger.info("Reloaded all widget timelines")
    }

    // MARK: - Session Completion

    /// Call this when a session completes to update all relevant widgets
    func onSessionCompleted(
        scenarioTitle: String,
        overallScore: Int,
        sessionDate: Date
    ) {
        // Update last session
        updateLastSessionData(
            scenarioTitle: scenarioTitle,
            overallScore: overallScore,
            sessionDate: sessionDate
        )

        logger.info("Session completed, widgets updated")
    }
}
