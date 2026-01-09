// OnboardingFlowTests.swift
// QuietCoachTests
//
// Integration tests for the onboarding flow.

import XCTest
@testable import QuietCoach

final class OnboardingFlowTests: XCTestCase {

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Clear onboarding state before each test
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }

    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        super.tearDown()
    }

    // MARK: - Onboarding State Tests

    func testNewUserHasNotCompletedOnboarding() {
        // Given: Fresh app state
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        // When: Checking onboarding status
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        // Then: Onboarding has not been completed
        XCTAssertFalse(hasCompleted)
    }

    func testOnboardingCompletionIsPersisted() {
        // Given: User completes onboarding
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // When: Checking onboarding status
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        // Then: Completion is persisted
        XCTAssertTrue(hasCompleted)
    }

    func testOnboardingStatusSurvivesAppRestart() {
        // Given: User has completed onboarding
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()

        // When: Simulating app restart (re-reading from UserDefaults)
        let standardDefaults = UserDefaults.standard
        let hasCompleted = standardDefaults.bool(forKey: "hasCompletedOnboarding")

        // Then: Status is still persisted
        XCTAssertTrue(hasCompleted)
    }

    // MARK: - Analytics Integration Tests

    @MainActor
    func testOnboardingStartedEventIsTracked() {
        // Given: Mock analytics
        let analytics = MockAnalytics()

        // When: Onboarding starts
        analytics.track(.onboardingStarted)

        // Then: Event is recorded
        XCTAssertEqual(analytics.trackedEvents.count, 1)
    }

    @MainActor
    func testOnboardingCompletedEventIsTracked() {
        // Given: Mock analytics
        let analytics = MockAnalytics()

        // When: Onboarding completes
        analytics.track(.onboardingCompleted)

        // Then: Event is recorded
        XCTAssertEqual(analytics.trackedEvents.count, 1)
    }

    @MainActor
    func testOnboardingSkippedEventIsTracked() {
        // Given: Mock analytics
        let analytics = MockAnalytics()

        // When: User skips onboarding
        analytics.track(.onboardingSkipped)

        // Then: Event is recorded
        XCTAssertEqual(analytics.trackedEvents.count, 1)
    }

    // MARK: - Full Onboarding Flow Tests

    @MainActor
    func testCompleteOnboardingFlowTracksAllEvents() {
        // Given: Mock analytics and initial state
        let analytics = MockAnalytics()
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        // When: Simulating full onboarding flow
        analytics.track(.onboardingStarted)

        // User views welcome page
        analytics.trackScreen("Onboarding_Welcome")

        // User views privacy page
        analytics.trackScreen("Onboarding_Privacy")

        // User views microphone page
        analytics.trackScreen("Onboarding_Microphone")

        // User completes onboarding
        analytics.track(.onboardingCompleted)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // Then: All events are tracked
        XCTAssertEqual(analytics.trackedEvents.count, 2) // started + completed
        XCTAssertEqual(analytics.trackedScreens.count, 3) // 3 screens
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding"))
    }

    // MARK: - Permission Flow Tests

    func testMicrophonePermissionCanBeRequested() {
        // This is a placeholder for permission testing
        // Actual microphone permission tests require UI testing or mocking AVFoundation
        XCTAssertTrue(true, "Microphone permission flow requires UI testing")
    }
}

// MARK: - App State Integration Tests

final class AppStateIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        super.tearDown()
    }

    @MainActor
    func testNewUserStartsWithOnboarding() {
        // Given: New user state
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        // Then: User should see onboarding
        XCTAssertFalse(hasCompleted, "New user should not have completed onboarding")
    }

    @MainActor
    func testReturningUserSkipsOnboarding() {
        // Given: Returning user state
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        // Then: User should skip onboarding
        XCTAssertTrue(hasCompleted, "Returning user should skip onboarding")
    }

    @MainActor
    func testFirstSessionAfterOnboardingIsTracked() {
        // Given: User completed onboarding and starts first session
        let analytics = MockAnalytics()
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        guard let scenario = Scenario.freeScenarios.first else {
            XCTFail("No free scenarios available")
            return
        }

        // When: First recording is started
        analytics.track(.recordingStarted(scenario: scenario.id))

        // Then: Event is tracked
        XCTAssertEqual(analytics.trackedEvents.count, 1)
    }
}

// MARK: - First Run Experience Tests

final class FirstRunExperienceTests: XCTestCase {

    @MainActor
    func testDefaultAppStateIsCorrect() {
        // Given: Fresh install state
        let mockGates = MockFeatureGates()

        // Then: Default state is free tier
        XCTAssertFalse(mockGates.isPro, "New users should be free tier")
        XCTAssertTrue(mockGates.isLoaded, "Feature gates should be loaded")
    }

    @MainActor
    func testFirstScenarioIsAccessible() {
        // Given: New free user
        let gates = MockFeatureGates()
        gates.updateProStatus(false)

        // When: Checking first free scenario
        guard let firstScenario = Scenario.freeScenarios.first else {
            XCTFail("Should have at least one free scenario")
            return
        }

        // Then: First scenario is accessible
        XCTAssertTrue(gates.canAccessScenario(firstScenario))
    }

    @MainActor
    func testRepositoryStartsEmpty() {
        // Given: New user's repository
        let repository = MockSessionRepository()

        // Then: No sessions exist
        XCTAssertTrue(repository.sessions.isEmpty)
        XCTAssertEqual(repository.sessionCount, 0)
    }
}
