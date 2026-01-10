// IntegrationTests.swift
// QuietCoachTests
//
// End-to-end integration tests for the complete recording → analysis → feedback → storage flow.
// Tests the full user journey through the app.

import XCTest
@testable import QuietCoach

// MARK: - Full Recording Flow Integration Tests

final class FullRecordingFlowIntegrationTests: XCTestCase {

    var mockRepository: MockSessionRepository!
    var mockAnalytics: MockAnalytics!
    var mockFeatureGates: MockFeatureGates!

    @MainActor
    func setUpMocks() {
        mockRepository = MockSessionRepository()
        mockAnalytics = MockAnalytics()
        mockFeatureGates = MockFeatureGates()
    }

    // MARK: - Happy Path Tests

    @MainActor
    func testCompleteRecordingFlowFromStartToFinish() {
        setUpMocks()

        // Given: A scenario and recording metrics
        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        let metrics = AudioMetrics.mock(duration: 90, averageLevel: 0.35)

        // When: Full flow is executed
        // 1. Generate scores from audio metrics
        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)
        XCTAssertGreaterThan(scores.overall, 0, "Scores should be generated")

        // 2. Generate coach notes
        let notes = CoachNotesEngine.generateNotes(metrics: metrics, scores: scores, scenario: scenario)
        XCTAssertNotNil(notes, "Notes should be generated")

        // 3. Generate try again focus
        let focus = CoachNotesEngine.generateTryAgainFocus(scores: scores, scenario: scenario)
        XCTAssertFalse(focus.goal.isEmpty, "Focus should have a goal")

        // 4. Save session
        let session = mockRepository.createSession(
            scenarioId: scenario.id,
            duration: metrics.duration,
            audioFileName: "integration_test.m4a",
            scores: scores,
            coachNotes: notes,
            tryAgainFocus: focus,
            metrics: metrics
        )

        // Then: Session is properly saved
        XCTAssertEqual(mockRepository.sessions.count, 1)
        XCTAssertEqual(session.scenarioId, scenario.id)
        XCTAssertNotNil(session.scores)
        XCTAssertEqual(session.scores?.overall, scores.overall)
    }

    @MainActor
    func testMultipleRecordingsForSameScenario() {
        setUpMocks()
        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // Record multiple sessions with improving scores
        let attempts = [
            (60, Float(0.25)),  // First attempt - lower scores
            (75, Float(0.35)),  // Second attempt - better
            (90, Float(0.45))   // Third attempt - best
        ]

        var previousScores: FeedbackScores?

        for (duration, level) in attempts {
            let metrics = AudioMetrics.mock(duration: TimeInterval(duration), averageLevel: level)
            let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)
            let notes = CoachNotesEngine.generateNotes(metrics: metrics, scores: scores, scenario: scenario)
            let focus = CoachNotesEngine.generateTryAgainFocus(scores: scores, scenario: scenario)

            _ = mockRepository.createSession(
                scenarioId: scenario.id,
                duration: metrics.duration,
                audioFileName: "attempt_\(duration).m4a",
                scores: scores,
                coachNotes: notes,
                tryAgainFocus: focus,
                metrics: metrics
            )

            // Track improvement
            if let prev = previousScores {
                let delta = scores.delta(from: prev)
                XCTAssertNotNil(delta, "Should be able to calculate delta")
            }

            previousScores = scores
        }

        // Verify all sessions saved
        let scenarioSessions = mockRepository.sessions(for: scenario.id)
        XCTAssertEqual(scenarioSessions.count, 3, "All attempts should be saved")
    }

    // MARK: - Analytics Integration Tests

    @MainActor
    func testAnalyticsTrackedThroughRecordingFlow() {
        setUpMocks()
        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // Simulate recording flow with analytics
        mockAnalytics.trackScreen("Rehearse")
        mockAnalytics.track(.recordingStarted(scenario: scenario.id))

        let metrics = AudioMetrics.mock(duration: 60, averageLevel: 0.3)
        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)

        mockAnalytics.track(.recordingCompleted(durationSeconds: Int(metrics.duration)))
        mockAnalytics.trackScreen("Review")
        mockAnalytics.track(.feedbackViewed(overallScore: scores.overall))

        // Verify analytics tracked
        XCTAssertEqual(mockAnalytics.trackedScreens.count, 2)
        XCTAssertTrue(mockAnalytics.trackedScreens.contains("Rehearse"))
        XCTAssertTrue(mockAnalytics.trackedScreens.contains("Review"))
        XCTAssertGreaterThanOrEqual(mockAnalytics.trackedEvents.count, 3)
    }

    // MARK: - Error Handling Integration Tests

    func testRecordingFlowHandlesAnalysisFailure() async {
        // Given: A speech analyzer configured to fail
        let mockAnalyzer = MockSpeechAnalyzer()
        await mockAnalyzer.setShouldFail(true)

        // When: Analysis is attempted
        do {
            _ = try await mockAnalyzer.analyze(
                audioURL: URL(fileURLWithPath: "/tmp/test.m4a"),
                duration: 60
            )
            XCTFail("Should have thrown error")
        } catch {
            // Then: Error is properly typed
            XCTAssertTrue(error is SpeechAnalysisError)
        }
    }

    @MainActor
    func testRecordingFlowWithMinimumDuration() {
        // Given: Recording at minimum duration
        let metrics = AudioMetrics.mock(
            duration: Constants.Limits.minRecordingDuration,
            averageLevel: 0.3
        )

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // When: Processing minimum duration recording
        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)

        // Then: Still generates valid scores
        XCTAssertGreaterThanOrEqual(scores.overall, 0)
        XCTAssertLessThanOrEqual(scores.overall, 100)
    }

    @MainActor
    func testRecordingFlowWithMaximumDuration() {
        // Given: Recording at maximum duration
        let sampleCount = Int(Constants.Limits.maxRecordingDuration * 10) // 10 samples per second
        let rmsWindows = Array(repeating: Float(0.35), count: sampleCount)
        let peakWindows = Array(repeating: Float(0.5), count: sampleCount)

        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: peakWindows,
            duration: Constants.Limits.maxRecordingDuration
        )

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // When: Processing maximum duration recording
        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)

        // Then: Still generates valid scores
        XCTAssertGreaterThanOrEqual(scores.overall, 0)
        XCTAssertLessThanOrEqual(scores.overall, 100)
    }

    // MARK: - Session Storage Integration Tests

    @MainActor
    func testSessionPersistenceAndRetrieval() {
        setUpMocks()
        // Given: Multiple sessions for different scenarios
        let scenarios = Array(Scenario.allScenarios.prefix(3))

        for scenario in scenarios {
            let metrics = AudioMetrics.mock(duration: 60, averageLevel: 0.3)
            let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)
            let notes = CoachNotesEngine.generateNotes(metrics: metrics, scores: scores, scenario: scenario)
            let focus = CoachNotesEngine.generateTryAgainFocus(scores: scores, scenario: scenario)

            _ = mockRepository.createSession(
                scenarioId: scenario.id,
                duration: metrics.duration,
                audioFileName: "\(scenario.id)_test.m4a",
                scores: scores,
                coachNotes: notes,
                tryAgainFocus: focus,
                metrics: metrics
            )
        }

        // When: Retrieving sessions
        XCTAssertEqual(mockRepository.sessionCount, 3)

        // Then: Each scenario has exactly one session
        for scenario in scenarios {
            let sessions = mockRepository.sessions(for: scenario.id)
            XCTAssertEqual(sessions.count, 1, "Scenario \(scenario.id) should have 1 session")
        }
    }

    @MainActor
    func testSessionDeletionRemovesFromRepository() {
        setUpMocks()
        // Given: A saved session
        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        let metrics = AudioMetrics.mock(duration: 60, averageLevel: 0.3)
        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)

        let session = mockRepository.createSession(
            scenarioId: scenario.id,
            duration: metrics.duration,
            audioFileName: "to_delete.m4a",
            scores: scores,
            coachNotes: [],
            tryAgainFocus: TryAgainFocus.default,
            metrics: metrics
        )

        XCTAssertEqual(mockRepository.sessions.count, 1)

        // When: Session is deleted
        mockRepository.deleteSession(session)

        // Then: Session is removed
        XCTAssertEqual(mockRepository.sessions.count, 0)
        XCTAssertEqual(mockRepository.deleteCallCount, 1)
    }

    @MainActor
    func testDeleteAllSessionsClearsRepository() {
        setUpMocks()
        // Given: Multiple sessions
        let scenarios = Array(Scenario.allScenarios.prefix(5))

        for scenario in scenarios {
            let scores = FeedbackScores(clarity: 70, pacing: 75, tone: 80, confidence: 65)
            _ = mockRepository.createSession(
                scenarioId: scenario.id,
                duration: 60,
                audioFileName: "\(scenario.id).m4a",
                scores: scores,
                coachNotes: [],
                tryAgainFocus: TryAgainFocus.default,
                metrics: AudioMetrics.empty
            )
        }

        XCTAssertEqual(mockRepository.sessions.count, 5)

        // When: All sessions deleted
        mockRepository.deleteAllSessions()

        // Then: Repository is empty
        XCTAssertEqual(mockRepository.sessions.count, 0)
    }
}

// MARK: - Feature Gate Integration Tests

final class FeatureGateIntegrationTests: XCTestCase {

    @MainActor
    func testFreeUserScenarioAccessLimited() {
        let featureGates = MockFeatureGates()
        featureGates.updateProStatus(false)

        var accessibleCount = 0
        var lockedCount = 0

        for scenario in Scenario.allScenarios {
            if featureGates.canAccessScenario(scenario) {
                accessibleCount += 1
            } else {
                lockedCount += 1
            }
        }

        XCTAssertEqual(accessibleCount, Constants.Limits.freeScenariosCount)
        XCTAssertGreaterThan(lockedCount, 0, "Some scenarios should be locked for free users")
    }

    @MainActor
    func testProUpgradeUnlocksAllScenarios() {
        let featureGates = MockFeatureGates()

        // Start as free user
        featureGates.updateProStatus(false)
        let freeAccessible = Scenario.allScenarios.filter { featureGates.canAccessScenario($0) }.count

        // Upgrade to pro
        featureGates.updateProStatus(true)
        let proAccessible = Scenario.allScenarios.filter { featureGates.canAccessScenario($0) }.count

        XCTAssertLessThan(freeAccessible, proAccessible)
        XCTAssertEqual(proAccessible, Scenario.allScenarios.count)
    }

    @MainActor
    func testSessionLimitEnforcedForFreeUsers() {
        let featureGates = MockFeatureGates()
        featureGates.updateProStatus(false)

        let repository = MockSessionRepository()

        // Create sessions up to the limit
        for i in 0..<Constants.Limits.freeSessionLimit {
            let scores = FeedbackScores(clarity: 70, pacing: 75, tone: 80, confidence: 65)
            _ = repository.createSession(
                scenarioId: "scenario-\(i)",
                duration: 60,
                audioFileName: "session_\(i).m4a",
                scores: scores,
                coachNotes: [],
                tryAgainFocus: TryAgainFocus.default,
                metrics: AudioMetrics.empty
            )
        }

        // Verify at limit
        XCTAssertEqual(repository.sessionCount, Constants.Limits.freeSessionLimit)

        // Free user has limited visible sessions
        XCTAssertFalse(featureGates.hasUnlimitedHistory)
        XCTAssertEqual(featureGates.maxVisibleSessions, 3)
    }
}

// MARK: - Streak Integration Tests

final class StreakIntegrationTests: XCTestCase {

    @MainActor
    func testStreakIncreasesWithDailyPractice() {
        // Reset streak for testing
        StreakTracker.shared.reset()

        let tracker = StreakTracker.shared
        let initialStreak = tracker.currentStreak

        // Record today's practice
        tracker.recordPractice()

        // Streak should be at least 1
        XCTAssertGreaterThanOrEqual(tracker.currentStreak, 1)
        XCTAssertGreaterThanOrEqual(tracker.currentStreak, initialStreak)
    }

    @MainActor
    func testLongestStreakTracked() {
        // Reset streak for testing
        StreakTracker.shared.reset()

        let tracker = StreakTracker.shared

        // Record practice
        tracker.recordPractice()

        // Longest streak should be at least current
        XCTAssertGreaterThanOrEqual(tracker.longestStreak, tracker.currentStreak)
    }
}

// MARK: - Performance Integration Tests

final class PerformanceIntegrationTests: XCTestCase {

    @MainActor
    func testScoreGenerationPerformance() {
        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        measure {
            for _ in 0..<100 {
                let metrics = AudioMetrics.mock(duration: 60, averageLevel: 0.3)
                _ = FeedbackEngine.generateScores(from: metrics, scenario: scenario)
            }
        }
    }

    @MainActor
    func testCoachNotesGenerationPerformance() {
        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        let metrics = AudioMetrics.mock(duration: 60, averageLevel: 0.3)
        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)

        measure {
            for _ in 0..<100 {
                _ = CoachNotesEngine.generateNotes(metrics: metrics, scores: scores, scenario: scenario)
            }
        }
    }

    func testLargeMetricsProcessing() {
        // Test with large metrics (simulating long recording)
        let sampleCount = 36000 // 1 hour at 10 samples/sec
        let rmsWindows = (0..<sampleCount).map { _ in Float.random(in: 0.1...0.5) }
        let peakWindows = (0..<sampleCount).map { _ in Float.random(in: 0.2...0.7) }

        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: peakWindows,
            duration: 3600
        )

        measure {
            // Should process quickly even with large data
            let _ = metrics.averageRMS
            let _ = metrics.rmsStandardDeviation
        }
    }
}

// MARK: - Data Export Integration Tests

final class DataExportIntegrationTests: XCTestCase {

    @MainActor
    func testExportContainsAllSessions() {
        let repository = MockSessionRepository()

        // Create test sessions
        for i in 0..<5 {
            let scores = FeedbackScores(clarity: 70 + i, pacing: 75, tone: 80, confidence: 65)
            _ = repository.createSession(
                scenarioId: "scenario-\(i)",
                duration: TimeInterval(60 + i * 10),
                audioFileName: "session_\(i).m4a",
                scores: scores,
                coachNotes: [],
                tryAgainFocus: TryAgainFocus.default,
                metrics: AudioMetrics.empty
            )
        }

        // Export data
        guard let exportData = repository.exportAllData() else {
            XCTFail("Export should return data")
            return
        }

        // Verify export contains data
        XCTAssertGreaterThan(exportData.count, 0)

        // Verify it's valid JSON
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: exportData))
    }
}

// MARK: - Concurrent Access Tests

final class ConcurrentAccessTests: XCTestCase {

    @MainActor
    func testConcurrentScoreGeneration() async {
        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // Generate scores concurrently
        await withTaskGroup(of: FeedbackScores.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    let metrics = AudioMetrics.mock(duration: 60, averageLevel: Float.random(in: 0.2...0.5))
                    return await FeedbackEngine.generateScores(from: metrics, scenario: scenario)
                }
            }

            var results: [FeedbackScores] = []
            for await scores in group {
                results.append(scores)
            }

            // All should complete successfully
            XCTAssertEqual(results.count, 10)

            // All scores should be valid
            for scores in results {
                XCTAssertGreaterThanOrEqual(scores.overall, 0)
                XCTAssertLessThanOrEqual(scores.overall, 100)
            }
        }
    }
}
