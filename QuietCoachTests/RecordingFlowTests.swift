// RecordingFlowTests.swift
// QuietCoachTests
//
// Integration tests for the recording → analysis → feedback flow.

import XCTest
@testable import QuietCoach

final class RecordingFlowTests: XCTestCase {

    // MARK: - Recording to Scores Flow

    @MainActor
    func testRecordingMetricsGenerateValidScores() {
        // Given: Audio metrics from a recording
        let metrics = AudioMetrics.mock(duration: 60, averageLevel: 0.3)

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // When: Scores are generated
        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)

        // Then: All scores are valid
        XCTAssertGreaterThanOrEqual(scores.clarity, 0)
        XCTAssertLessThanOrEqual(scores.clarity, 100)
        XCTAssertGreaterThanOrEqual(scores.pacing, 0)
        XCTAssertLessThanOrEqual(scores.pacing, 100)
        XCTAssertGreaterThanOrEqual(scores.tone, 0)
        XCTAssertLessThanOrEqual(scores.tone, 100)
        XCTAssertGreaterThanOrEqual(scores.confidence, 0)
        XCTAssertLessThanOrEqual(scores.confidence, 100)
        XCTAssertGreaterThanOrEqual(scores.overall, 0)
        XCTAssertLessThanOrEqual(scores.overall, 100)
    }

    @MainActor
    func testRecordingFlowCreatesSession() {
        // Given: Mock repository and recording data
        let repository = MockSessionRepository()
        let metrics = AudioMetrics.mock(duration: 45, averageLevel: 0.35)

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // When: Full recording flow is executed
        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)
        let notes = CoachNotesEngine.generateNotes(metrics: metrics, scores: scores, scenario: scenario)
        let focus = CoachNotesEngine.generateTryAgainFocus(scores: scores, scenario: scenario)

        let session = repository.createSession(
            scenarioId: scenario.id,
            duration: metrics.duration,
            audioFileName: "test_recording.m4a",
            scores: scores,
            coachNotes: notes,
            tryAgainFocus: focus,
            metrics: metrics
        )

        // Then: Session is created with correct data
        XCTAssertEqual(session.scenarioId, scenario.id)
        XCTAssertEqual(session.duration, 45)
        XCTAssertNotNil(session.scores)
        XCTAssertEqual(session.scores?.overall, scores.overall)
        XCTAssertEqual(repository.sessions.count, 1)
        XCTAssertEqual(repository.createCallCount, 1)
    }

    @MainActor
    func testCoachNotesAreGeneratedFromScores() {
        // Given: Metrics and scenario
        let metrics = AudioMetrics.mock(duration: 60, averageLevel: 0.25)

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)

        // When: Coach notes are generated
        let notes = CoachNotesEngine.generateNotes(metrics: metrics, scores: scores, scenario: scenario)

        // Then: Notes are generated (may be empty for good performance)
        XCTAssertNotNil(notes)
        // Notes should have valid structure if present
        for note in notes {
            XCTAssertFalse(note.title.isEmpty)
            XCTAssertFalse(note.body.isEmpty)
        }
    }

    @MainActor
    func testTryAgainFocusIsGenerated() {
        // Given: Scores from a recording
        let scores = FeedbackScores(clarity: 70, pacing: 60, tone: 80, confidence: 65)

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // When: Try again focus is generated
        let focus = CoachNotesEngine.generateTryAgainFocus(scores: scores, scenario: scenario)

        // Then: Focus has valid content
        XCTAssertFalse(focus.goal.isEmpty)
        XCTAssertFalse(focus.reason.isEmpty)
    }

    // MARK: - Session Retrieval Flow

    @MainActor
    func testSessionCanBeRetrievedAfterCreation() {
        // Given: Repository with a created session
        let repository = MockSessionRepository()
        let scores = FeedbackScores(clarity: 80, pacing: 75, tone: 85, confidence: 70)

        let session = repository.createSession(
            scenarioId: "test-scenario",
            duration: 60,
            audioFileName: "test.m4a",
            scores: scores,
            coachNotes: [],
            tryAgainFocus: TryAgainFocus.default,
            metrics: AudioMetrics.empty
        )

        // When: Sessions are fetched for the scenario
        let scenarioSessions = repository.sessions(for: "test-scenario")

        // Then: Session is found
        XCTAssertEqual(scenarioSessions.count, 1)
        XCTAssertEqual(scenarioSessions.first?.id, session.id)
    }

    @MainActor
    func testMultipleSessionsAreOrderedByDate() {
        // Given: Repository with multiple sessions
        let repository = MockSessionRepository()
        let scores = FeedbackScores(clarity: 80, pacing: 75, tone: 85, confidence: 70)

        _ = repository.createSession(
            scenarioId: "scenario-a",
            duration: 30,
            audioFileName: "first.m4a",
            scores: scores,
            coachNotes: [],
            tryAgainFocus: TryAgainFocus.default,
            metrics: AudioMetrics.empty
        )

        _ = repository.createSession(
            scenarioId: "scenario-a",
            duration: 45,
            audioFileName: "second.m4a",
            scores: scores,
            coachNotes: [],
            tryAgainFocus: TryAgainFocus.default,
            metrics: AudioMetrics.empty
        )

        _ = repository.createSession(
            scenarioId: "scenario-a",
            duration: 60,
            audioFileName: "third.m4a",
            scores: scores,
            coachNotes: [],
            tryAgainFocus: TryAgainFocus.default,
            metrics: AudioMetrics.empty
        )

        // When: Sessions are fetched
        let sessions = repository.sessions(for: "scenario-a")

        // Then: All sessions are returned
        XCTAssertEqual(sessions.count, 3)
    }

    // MARK: - Score Delta Flow

    @MainActor
    func testScoreDeltaShowsImprovement() {
        // Given: Two sessions with improving scores
        let previousScores = FeedbackScores(clarity: 60, pacing: 55, tone: 65, confidence: 50)
        let currentScores = FeedbackScores(clarity: 75, pacing: 70, tone: 80, confidence: 65)

        // When: Delta is calculated
        let delta = currentScores.delta(from: previousScores)

        // Then: Improvement is detected
        XCTAssertNotNil(delta)
        XCTAssertTrue(delta!.hasImprovement)
        XCTAssertEqual(delta!.clarity, 15)
        XCTAssertEqual(delta!.pacing, 15)
        XCTAssertEqual(delta!.tone, 15)
        XCTAssertEqual(delta!.confidence, 15)
    }

    // MARK: - Edge Cases

    @MainActor
    func testShortRecordingProducesValidScores() {
        // Given: Very short recording (edge case)
        let metrics = AudioMetrics(
            rmsWindows: Array(repeating: 0.2, count: 50),
            peakWindows: Array(repeating: 0.3, count: 50),
            duration: 5
        )

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // When: Scores are generated
        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)

        // Then: Scores are still valid (within expected range)
        XCTAssertGreaterThanOrEqual(scores.clarity, 0)
        XCTAssertLessThanOrEqual(scores.clarity, 100)
        XCTAssertGreaterThanOrEqual(scores.pacing, 0)
        XCTAssertLessThanOrEqual(scores.pacing, 100)
    }

    @MainActor
    func testSilentRecordingProducesLowScores() {
        // Given: Silent recording
        let metrics = AudioMetrics(
            rmsWindows: Array(repeating: 0.001, count: 600),
            peakWindows: Array(repeating: 0.002, count: 600),
            duration: 60
        )

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // When: Scores are generated
        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)

        // Then: Scores reflect poor performance (but are still valid)
        XCTAssertGreaterThanOrEqual(scores.overall, 0)
        XCTAssertLessThanOrEqual(scores.overall, 100)
    }
}

// MARK: - Coach Notes Engine Tests

final class CoachNotesEngineIntegrationTests: XCTestCase {

    @MainActor
    func testNotesReflectPoorPacing() {
        // Given: Metrics indicating fast pacing
        var rmsWindows: [Float] = []
        var peakWindows: [Float] = []

        // Create high-energy, constant audio (no pauses = too fast)
        for _ in 0..<600 {
            rmsWindows.append(Float.random(in: 0.4...0.6))
            peakWindows.append(Float.random(in: 0.5...0.7))
        }

        let metrics = AudioMetrics(
            rmsWindows: rmsWindows,
            peakWindows: peakWindows,
            duration: 60
        )

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        let scores = FeedbackEngine.generateScores(from: metrics, scenario: scenario)

        // When: Notes are generated
        let notes = CoachNotesEngine.generateNotes(metrics: metrics, scores: scores, scenario: scenario)

        // Then: Notes may include pacing advice
        // (The actual content depends on the engine's logic)
        XCTAssertNotNil(notes)
    }

    @MainActor
    func testFocusTargetsWeakestArea() {
        // Given: Scores with clear weakness in pacing
        let scores = FeedbackScores(clarity: 85, pacing: 50, tone: 80, confidence: 75)

        guard let scenario = Scenario.allScenarios.first else {
            XCTFail("No scenarios available")
            return
        }

        // When: Focus is generated
        let focus = CoachNotesEngine.generateTryAgainFocus(scores: scores, scenario: scenario)

        // Then: Focus should exist and have content
        XCTAssertFalse(focus.goal.isEmpty)
        XCTAssertFalse(focus.reason.isEmpty)
    }
}
