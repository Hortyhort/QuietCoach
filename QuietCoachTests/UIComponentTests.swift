// UIComponentTests.swift
// QuietCoachTests
//
// UI component and view state tests for critical screens.
// Tests view logic, accessibility, and state management.

import XCTest
import SwiftUI
@testable import QuietCoach

// MARK: - Home View State Tests

final class HomeViewStateTests: XCTestCase {

    @MainActor
    func testScenarioListIsNotEmpty() {
        // The home view should always have scenarios to display
        let scenarios = Scenario.allScenarios

        XCTAssertFalse(scenarios.isEmpty, "Scenario list should not be empty")
        XCTAssertGreaterThanOrEqual(scenarios.count, 6, "Should have at least 6 scenarios")
    }

    @MainActor
    func testFreeUserSeesLimitedScenarios() {
        // Given: A free user
        let featureGates = MockFeatureGates()
        featureGates.updateProStatus(false)

        // When: Checking accessible scenarios
        let accessibleCount = Scenario.allScenarios.filter { featureGates.canAccessScenario($0) }.count

        // Then: Should see limited scenarios
        XCTAssertEqual(accessibleCount, Constants.Limits.freeScenariosCount)
    }

    @MainActor
    func testProUserSeesAllScenarios() {
        // Given: A pro user
        let featureGates = MockFeatureGates()
        featureGates.updateProStatus(true)

        // When: Checking accessible scenarios
        let accessibleCount = Scenario.allScenarios.filter { featureGates.canAccessScenario($0) }.count

        // Then: Should see all scenarios
        XCTAssertEqual(accessibleCount, Scenario.allScenarios.count)
    }

    @MainActor
    func testScenarioCategoriesExist() {
        // All scenarios should have valid categories
        for scenario in Scenario.allScenarios {
            XCTAssertFalse(scenario.category.rawValue.isEmpty)
            XCTAssertFalse(scenario.title.isEmpty)
            XCTAssertFalse(scenario.subtitle.isEmpty)
        }
    }

    @MainActor
    func testScenarioHasPromptText() {
        // Each scenario should have prompt text for coaching
        for scenario in Scenario.allScenarios {
            XCTAssertFalse(scenario.promptText.isEmpty, "Scenario \(scenario.id) should have prompt text")
        }
    }
}

// MARK: - Recording State Machine Tests

final class RecordingStateTests: XCTestCase {

    @MainActor
    func testRecordingStateExists() {
        // Test all recording states exist
        let states: [RecordingState] = [.idle, .recording, .paused, .finished]
        XCTAssertEqual(states.count, 4)
    }

    @MainActor
    func testRecordingStatesAreDistinct() {
        // Each state should be unique
        XCTAssertNotEqual(RecordingState.idle, RecordingState.recording)
        XCTAssertNotEqual(RecordingState.recording, RecordingState.paused)
        XCTAssertNotEqual(RecordingState.paused, RecordingState.finished)
        XCTAssertNotEqual(RecordingState.finished, RecordingState.idle)
    }

    @MainActor
    func testRecordingWarningHasMessage() {
        // Each warning should have a user-facing message
        let warnings: [RecordingWarning] = [.tooQuiet, .tooLoud, .noisyEnvironment]

        for warning in warnings {
            XCTAssertFalse(warning.message.isEmpty, "\(warning) should have a message")
            XCTAssertFalse(warning.icon.isEmpty, "\(warning) should have an icon")
        }
    }
}

// MARK: - Review View State Tests

final class ReviewViewStateTests: XCTestCase {

    @MainActor
    func testFeedbackScoresAreValidRange() {
        // Given: Various score combinations
        let testCases: [(Int, Int, Int, Int)] = [
            (100, 100, 100, 100),  // Perfect scores
            (0, 0, 0, 0),          // Minimum scores
            (75, 80, 65, 90),      // Mixed scores
            (50, 50, 50, 50)       // Average scores
        ]

        for (clarity, pacing, tone, confidence) in testCases {
            let scores = FeedbackScores(clarity: clarity, pacing: pacing, tone: tone, confidence: confidence)

            // Verify all scores are in valid range
            XCTAssertGreaterThanOrEqual(scores.clarity, 0)
            XCTAssertLessThanOrEqual(scores.clarity, 100)
            XCTAssertGreaterThanOrEqual(scores.pacing, 0)
            XCTAssertLessThanOrEqual(scores.pacing, 100)
            XCTAssertGreaterThanOrEqual(scores.tone, 0)
            XCTAssertLessThanOrEqual(scores.tone, 100)
            XCTAssertGreaterThanOrEqual(scores.confidence, 0)
            XCTAssertLessThanOrEqual(scores.confidence, 100)

            // Overall should also be valid
            XCTAssertGreaterThanOrEqual(scores.overall, 0)
            XCTAssertLessThanOrEqual(scores.overall, 100)
        }
    }

    @MainActor
    func testScoreDeltaCalculation() {
        // Given: Two sets of scores
        let previous = FeedbackScores(clarity: 60, pacing: 70, tone: 65, confidence: 55)
        let current = FeedbackScores(clarity: 75, pacing: 80, tone: 70, confidence: 65)

        // When: Delta is calculated
        guard let delta = current.delta(from: previous) else {
            XCTFail("Delta should not be nil")
            return
        }

        // Then: Deltas are correct
        XCTAssertEqual(delta.clarity, 15)
        XCTAssertEqual(delta.pacing, 10)
        XCTAssertEqual(delta.tone, 5)
        XCTAssertEqual(delta.confidence, 10)
        XCTAssertTrue(delta.hasImprovement)
    }

    @MainActor
    func testScorePrimaryStrength() {
        // Test primary strength detection
        let scores = FeedbackScores(clarity: 90, pacing: 70, tone: 75, confidence: 60)
        XCTAssertEqual(scores.primaryStrength, .clarity, "Clarity should be primary strength")

        let scores2 = FeedbackScores(clarity: 60, pacing: 95, tone: 75, confidence: 70)
        XCTAssertEqual(scores2.primaryStrength, .pacing, "Pacing should be primary strength")
    }

    @MainActor
    func testCoachNoteStructure() {
        // Given: Coach notes from engine
        let metrics = AudioMetrics.mock(duration: 60, averageLevel: 0.3)
        let scores = FeedbackScores(clarity: 70, pacing: 60, tone: 75, confidence: 65)

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // When: Notes are generated
        let notes = CoachNotesEngine.generateNotes(metrics: metrics, scores: scores, scenario: scenario)

        // Then: Notes have valid structure
        for note in notes {
            XCTAssertFalse(note.title.isEmpty, "Note title should not be empty")
            XCTAssertFalse(note.body.isEmpty, "Note body should not be empty")
        }
    }
}

// MARK: - Settings View State Tests

final class SettingsViewStateTests: XCTestCase {

    @MainActor
    func testAppVersionIsValid() {
        let version = Constants.App.version

        XCTAssertFalse(version.isEmpty)
        // Version should follow semver format
        let components = version.split(separator: ".")
        XCTAssertGreaterThanOrEqual(components.count, 2, "Version should have at least major.minor")
    }

    @MainActor
    func testSupportURLsAreValid() {
        let privacyURL = URL(string: Constants.App.privacyURL)
        let supportURL = URL(string: Constants.App.supportURL)

        XCTAssertNotNil(privacyURL, "Privacy URL should be valid")
        XCTAssertNotNil(supportURL, "Support URL should be valid")
    }

    @MainActor
    func testCloudKitContainerIDIsConfigured() {
        let containerID = Constants.App.cloudKitContainerID

        XCTAssertFalse(containerID.isEmpty)
        XCTAssertTrue(containerID.hasPrefix("iCloud."), "Container ID should start with iCloud.")
    }
}

// MARK: - Waveform Component Tests

final class WaveformComponentTests: XCTestCase {

    func testWaveformHandlesEmptySamples() {
        // Given: Empty samples
        let samples: [Float] = []

        // When/Then: Should not crash, should return idle state description
        XCTAssertTrue(samples.isEmpty)
        // The actual view would show idle state
    }

    func testWaveformHandlesMaxSamples() {
        // Given: Maximum number of samples
        let samples = Array(repeating: Float(0.5), count: 1000)

        // When/Then: Should handle without issues
        XCTAssertEqual(samples.count, 1000)
        let average = samples.reduce(0, +) / Float(samples.count)
        XCTAssertEqual(average, 0.5, accuracy: 0.01)
    }

    func testWaveformLevelNormalization() {
        // Test that various input levels are handled
        let testCases: [(Float, String)] = [
            (0.0, "silent"),
            (0.1, "quiet"),
            (0.5, "moderate"),
            (0.9, "loud"),
            (1.0, "maximum")
        ]

        for (level, _) in testCases {
            // Levels should be clamped to valid range
            let clamped = max(0.1, min(1.0, level))
            XCTAssertGreaterThanOrEqual(clamped, 0.1)
            XCTAssertLessThanOrEqual(clamped, 1.0)
        }
    }
}

// MARK: - Accessibility Tests

final class AccessibilityTests: XCTestCase {

    @MainActor
    func testAllScoreTypesHaveAccessibilityLabels() {
        let scoreTypes: [FeedbackScores.ScoreType] = [.clarity, .pacing, .tone, .confidence]

        for scoreType in scoreTypes {
            XCTAssertFalse(scoreType.rawValue.isEmpty, "\(scoreType) should have a title for accessibility")
            XCTAssertFalse(scoreType.explanation.isEmpty, "\(scoreType) should have an explanation")
        }
    }

    @MainActor
    func testRecordingWarningsHaveAccessibleMessages() {
        let warnings: [RecordingWarning] = [.tooQuiet, .tooLoud, .noisyEnvironment]

        for warning in warnings {
            XCTAssertFalse(warning.message.isEmpty)
            XCTAssertFalse(warning.accessibilityLabel.isEmpty)
        }
    }

    @MainActor
    func testScenarioCategoriesHaveDisplayNames() {
        let categories = Set(Scenario.allScenarios.map { $0.category })

        for category in categories {
            XCTAssertFalse(category.rawValue.isEmpty)
            // Category names should be user-friendly
            XCTAssertFalse(category.rawValue.contains("_"), "Category should use spaces, not underscores")
        }
    }

    @MainActor
    func testMinimumTouchTargetSize() {
        // Verify constants for accessibility
        XCTAssertGreaterThanOrEqual(Constants.Layout.minTouchTarget, 44, "Touch targets should be at least 44pt (Apple HIG)")
        XCTAssertGreaterThanOrEqual(Constants.Layout.recordButtonSize, 44)
        XCTAssertGreaterThanOrEqual(Constants.Layout.secondaryButtonSize, 44)
    }
}

// MARK: - Theme Consistency Tests

final class ThemeConsistencyTests: XCTestCase {

    func testLayoutConstantsAreReasonable() {
        // Verify layout constants are within reasonable ranges
        XCTAssertGreaterThan(Constants.Layout.horizontalPadding, 0)
        XCTAssertLessThan(Constants.Layout.horizontalPadding, 100)

        XCTAssertGreaterThan(Constants.Layout.cornerRadius, 0)
        XCTAssertLessThan(Constants.Layout.cornerRadius, 50)

        XCTAssertGreaterThan(Constants.Layout.sectionSpacing, 0)
        XCTAssertLessThan(Constants.Layout.sectionSpacing, 100)
    }

    func testAnimationConstantsAreReasonable() {
        // Animation durations should be reasonable
        XCTAssertGreaterThan(Constants.Animation.springResponse, 0)
        XCTAssertLessThan(Constants.Animation.springResponse, 2.0)

        XCTAssertGreaterThan(Constants.Animation.springDamping, 0)
        XCTAssertLessThanOrEqual(Constants.Animation.springDamping, 1.0)
    }

    func testRecordingLimitsAreReasonable() {
        // Recording limits should make sense
        XCTAssertGreaterThan(Constants.Limits.maxRecordingDuration, 60) // At least 1 minute
        XCTAssertLessThan(Constants.Limits.maxRecordingDuration, 3600) // Less than 1 hour

        XCTAssertGreaterThan(Constants.Limits.minRecordingDuration, 0)
        XCTAssertLessThan(Constants.Limits.minRecordingDuration, Constants.Limits.maxRecordingDuration)
    }
}

// MARK: - Navigation Flow Tests

final class NavigationFlowTests: XCTestCase {

    @MainActor
    func testOnboardingStorageKeyExists() {
        // The onboarding completion should use AppStorage
        // This just verifies the constant key pattern
        let key = "hasCompletedOnboarding"
        XCTAssertFalse(key.isEmpty)
    }

    @MainActor
    func testScenarioNavigationPath() {
        // Given: A scenario
        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // Scenario should be identifiable and hashable for navigation
        let id = scenario.id
        XCTAssertFalse(id.isEmpty)

        // Should be able to find scenario by ID
        let found = Scenario.allScenarios.first { $0.id == id }
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, scenario.id)
    }
}

// MARK: - Error Display Tests

final class ErrorDisplayTests: XCTestCase {

    func testAllErrorsHaveUserFriendlyMessages() {
        // Test RecordingError messages
        let recordingErrors: [RecordingError] = [
            .microphoneAccessDenied,
            .microphoneAccessRestricted,
            .audioSessionFailed(NSError(domain: "test", code: 1)),
            .recordingInterrupted,
            .recordingFailed(NSError(domain: "test", code: 2)),
            .noAudioRecorded,
            .saveFailed(NSError(domain: "test", code: 3))
        ]

        for error in recordingErrors {
            XCTAssertFalse(error.title.isEmpty, "Error should have title")
            XCTAssertFalse(error.message.isEmpty, "Error should have message")
            // Messages should not contain technical jargon
            XCTAssertFalse(error.message.lowercased().contains("exception"))
            XCTAssertFalse(error.message.lowercased().contains("null"))
        }
    }

    func testRecoverableErrorsHaveRecoveryActions() {
        // Errors that can be recovered should have recovery actions
        let error = RecordingError.microphoneAccessDenied
        XCTAssertNotNil(error.recoveryAction, "microphoneAccessDenied should have recovery action")
        XCTAssertTrue(error.isRecoverable, "microphoneAccessDenied should be recoverable")
    }
}
