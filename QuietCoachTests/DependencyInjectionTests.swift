// DependencyInjectionTests.swift
// QuietCoachTests
//
// Unit tests for dependency injection infrastructure.

import XCTest
@testable import QuietCoach

final class DependencyInjectionTests: XCTestCase {

    // MARK: - AppContainer Tests

    @MainActor
    func testAppContainerProvidesDefaultDependencies() {
        let container = AppContainer.shared

        // All dependencies should be non-nil
        XCTAssertNotNil(container.sessionRepository)
        XCTAssertNotNil(container.featureGates)
        XCTAssertNotNil(container.speechAnalyzer)
        XCTAssertNotNil(container.analytics)
        XCTAssertNotNil(container.networkMonitor)
        XCTAssertNotNil(container.performanceMonitor)
        XCTAssertNotNil(container.crashReporting)
    }

    @MainActor
    func testAppContainerForTestingAllowsOverrides() {
        let mockGates = MockFeatureGates()
        mockGates.updateProStatus(true)

        let container = AppContainer.forTesting(
            featureGates: mockGates
        )

        // Should use our mock
        XCTAssertTrue(container.featureGates.isPro)
    }

    @MainActor
    func testAppContainerOverrideReplacesSpecificDependency() {
        let container = AppContainer.forTesting()
        let mockAnalytics = MockAnalytics()

        container.override(\.analytics, with: mockAnalytics)

        // The analytics should now be our mock
        // Track an event and verify it was captured
        container.analytics.track(.onboardingStarted)

        XCTAssertEqual(mockAnalytics.trackedEvents.count, 1)
    }
}

// MARK: - Mock Analytics Tests

final class MockAnalyticsTests: XCTestCase {

    @MainActor
    func testMockAnalyticsTracksEvents() {
        let analytics = MockAnalytics()

        analytics.track(.onboardingStarted)
        analytics.track(.recordingStarted(scenario: "test"))
        analytics.track(.feedbackViewed(overallScore: 85))

        XCTAssertEqual(analytics.trackedEvents.count, 3)
    }

    @MainActor
    func testMockAnalyticsTracksScreens() {
        let analytics = MockAnalytics()

        analytics.trackScreen("Home")
        analytics.trackScreen("Recording")
        analytics.trackScreen("Feedback")

        XCTAssertEqual(analytics.trackedScreens, ["Home", "Recording", "Feedback"])
    }

    @MainActor
    func testMockAnalyticsTracksUserProperties() {
        let analytics = MockAnalytics()

        analytics.setUserProperty("subscription_status", value: "pro")
        analytics.setUserProperty("app_version", value: "1.0.0")

        XCTAssertEqual(analytics.userProperties["subscription_status"], "pro")
        XCTAssertEqual(analytics.userProperties["app_version"], "1.0.0")
    }
}

// MARK: - Mock Session Repository Tests

final class MockSessionRepositoryTests: XCTestCase {

    @MainActor
    func testMockRepositoryStartsEmpty() {
        let repo = MockSessionRepository()

        XCTAssertTrue(repo.sessions.isEmpty)
        XCTAssertEqual(repo.sessionCount, 0)
        XCTAssertTrue(repo.isLoaded)
    }

    @MainActor
    func testMockRepositoryTracksMethodCalls() {
        let repo = MockSessionRepository()

        repo.fetchSessions()
        repo.fetchSessions()

        XCTAssertEqual(repo.fetchCallCount, 2)
    }

    @MainActor
    func testMockRepositoryCreateAddsSession() {
        let repo = MockSessionRepository()

        let scores = FeedbackScores(clarity: 80, pacing: 75, tone: 70, confidence: 85)
        _ = repo.createSession(
            scenarioId: "test-scenario",
            duration: 60,
            audioFileName: "test.m4a",
            scores: scores,
            coachNotes: [],
            tryAgainFocus: TryAgainFocus.default,
            metrics: AudioMetrics.empty
        )

        XCTAssertEqual(repo.sessions.count, 1)
        XCTAssertEqual(repo.createCallCount, 1)
    }

    @MainActor
    func testMockRepositoryDeleteRemovesSession() {
        let repo = MockSessionRepository()

        let scores = FeedbackScores(clarity: 80, pacing: 75, tone: 70, confidence: 85)
        let session = repo.createSession(
            scenarioId: "test-scenario",
            duration: 60,
            audioFileName: "test.m4a",
            scores: scores,
            coachNotes: [],
            tryAgainFocus: TryAgainFocus.default,
            metrics: AudioMetrics.empty
        )

        XCTAssertEqual(repo.sessions.count, 1)

        repo.deleteSession(session)

        XCTAssertEqual(repo.sessions.count, 0)
        XCTAssertEqual(repo.deleteCallCount, 1)
    }

    @MainActor
    func testMockRepositoryFiltersByScenario() {
        let repo = MockSessionRepository()
        let scores = FeedbackScores(clarity: 80, pacing: 75, tone: 70, confidence: 85)

        _ = repo.createSession(
            scenarioId: "scenario-a",
            duration: 60,
            audioFileName: "a1.m4a",
            scores: scores,
            coachNotes: [],
            tryAgainFocus: TryAgainFocus.default,
            metrics: AudioMetrics.empty
        )

        _ = repo.createSession(
            scenarioId: "scenario-b",
            duration: 60,
            audioFileName: "b1.m4a",
            scores: scores,
            coachNotes: [],
            tryAgainFocus: TryAgainFocus.default,
            metrics: AudioMetrics.empty
        )

        _ = repo.createSession(
            scenarioId: "scenario-a",
            duration: 60,
            audioFileName: "a2.m4a",
            scores: scores,
            coachNotes: [],
            tryAgainFocus: TryAgainFocus.default,
            metrics: AudioMetrics.empty
        )

        let scenarioASessions = repo.sessions(for: "scenario-a")
        XCTAssertEqual(scenarioASessions.count, 2)

        let scenarioBSessions = repo.sessions(for: "scenario-b")
        XCTAssertEqual(scenarioBSessions.count, 1)
    }
}

// MARK: - Mock Network Monitor Tests

final class MockNetworkMonitorTests: XCTestCase {

    @MainActor
    func testMockNetworkMonitorStartsConnected() {
        let monitor = MockNetworkMonitor()

        XCTAssertEqual(monitor.status, .connected)
        XCTAssertTrue(monitor.status.isConnected)
    }

    @MainActor
    func testMockNetworkMonitorCanBeSetOffline() {
        let monitor = MockNetworkMonitor()

        monitor.status = .disconnected

        XCTAssertEqual(monitor.status, .disconnected)
        XCTAssertFalse(monitor.status.isConnected)
    }

    @MainActor
    func testMockNetworkMonitorRetryExecutesOperation() async throws {
        let monitor = MockNetworkMonitor()
        var executionCount = 0

        let result = try await monitor.withRetry {
            executionCount += 1
            return "success"
        }

        XCTAssertEqual(result, "success")
        XCTAssertEqual(executionCount, 1)
    }
}

// MARK: - Mock Speech Analyzer Tests

final class MockSpeechAnalyzerTests: XCTestCase {

    func testMockSpeechAnalyzerReturnsDefaultResult() async throws {
        let analyzer = MockSpeechAnalyzer()

        let result = try await analyzer.analyze(
            audioURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            duration: 60,
            profile: .default
        )

        XCTAssertFalse(result.transcription.isEmpty)
        XCTAssertGreaterThan(result.clarity.score, 0)
        XCTAssertGreaterThan(result.pacing.score, 0)
    }

    func testMockSpeechAnalyzerCanBeConfiguredToFail() async {
        let analyzer = MockSpeechAnalyzer()
        await analyzer.setShouldFail(true)

        do {
            _ = try await analyzer.analyze(
                audioURL: URL(fileURLWithPath: "/tmp/test.m4a"),
                duration: 60,
                profile: .default
            )
            XCTFail("Should have thrown an error")
        } catch {
            // Expected
            XCTAssertTrue(error is SpeechAnalysisError)
        }
    }

    func testMockSpeechAnalyzerAuthorizationDefaultsToTrue() async {
        let analyzer = MockSpeechAnalyzer()

        let authorized = await analyzer.isAuthorized
        XCTAssertTrue(authorized)
    }
}

// Helper extension for MockSpeechAnalyzer
extension MockSpeechAnalyzer {
    func setShouldFail(_ value: Bool) async {
        shouldFail = value
    }
}

// MARK: - Mock Crash Reporting Tests

final class MockCrashReportingTests: XCTestCase {

    @MainActor
    func testMockCrashReportingRecordsErrors() {
        let crash = MockCrashReporting()

        let error = NSError(domain: "test", code: 1, userInfo: nil)
        crash.recordError(error, context: ["source": "test"])

        XCTAssertEqual(crash.recordedErrors.count, 1)
    }

    @MainActor
    func testMockCrashReportingRecordsBreadcrumbs() {
        let crash = MockCrashReporting()

        crash.recordBreadcrumb("User tapped button", category: .userAction, data: ["button": "start"])
        crash.recordBreadcrumb("Screen changed", category: .navigation, data: [:])

        XCTAssertEqual(crash.breadcrumbs.count, 2)
    }

    @MainActor
    func testMockCrashReportingRecordsScreenViews() {
        let crash = MockCrashReporting()

        crash.recordScreenView("Home")
        crash.recordScreenView("Recording")

        XCTAssertEqual(crash.screenViews, ["Home", "Recording"])
    }
}
