// SubscriptionFlowTests.swift
// QuietCoachTests
//
// Integration tests for subscription and feature gating flow.

import XCTest
@testable import QuietCoach

final class SubscriptionFlowTests: XCTestCase {

    // MARK: - Feature Access Tests

    @MainActor
    func testFreeUserCanAccessFreeScenarios() {
        // Given: Free user (not Pro)
        let gates = MockFeatureGates()
        gates.updateProStatus(false)

        // When: Checking access to free scenarios
        let freeScenarios = Scenario.freeScenarios

        // Then: All free scenarios are accessible
        XCTAssertGreaterThan(freeScenarios.count, 0, "Should have at least one free scenario")
        for scenario in freeScenarios {
            XCTAssertTrue(gates.canAccessScenario(scenario), "Free user should access free scenario: \(scenario.title)")
        }
    }

    @MainActor
    func testFreeUserCannotAccessProScenarios() {
        // Given: Free user
        let gates = MockFeatureGates()
        gates.updateProStatus(false)

        // When: Checking access to pro scenarios
        let proScenarios = Scenario.proScenarios

        // Then: Pro scenarios are blocked (if any exist)
        for scenario in proScenarios {
            XCTAssertFalse(gates.canAccessScenario(scenario), "Free user should not access pro scenario: \(scenario.title)")
        }
    }

    @MainActor
    func testProUserCanAccessAllScenarios() {
        // Given: Pro user
        let gates = MockFeatureGates()
        gates.updateProStatus(true)

        // When: Checking access to all scenarios
        let allScenarios = Scenario.allScenarios

        // Then: All scenarios are accessible
        for scenario in allScenarios {
            XCTAssertTrue(gates.canAccessScenario(scenario), "Pro user should access scenario: \(scenario.title)")
        }
    }

    // MARK: - Session History Limits

    @MainActor
    func testFreeUserHasLimitedSessionHistory() {
        // Given: Free user
        let gates = MockFeatureGates()
        gates.updateProStatus(false)

        // Then: Session limit is enforced
        XCTAssertFalse(gates.hasUnlimitedHistory)
        XCTAssertEqual(gates.maxVisibleSessions, 3, "Free users should see only 3 sessions")
    }

    @MainActor
    func testProUserHasUnlimitedSessionHistory() {
        // Given: Pro user
        let gates = MockFeatureGates()
        gates.updateProStatus(true)

        // Then: No session limit
        XCTAssertTrue(gates.hasUnlimitedHistory)
        XCTAssertEqual(gates.maxVisibleSessions, Int.max)
    }

    @MainActor
    func testSessionVisibilityRespectsLimit() {
        // Given: Repository with many sessions
        let repository = MockSessionRepository()
        let scores = FeedbackScores(clarity: 80, pacing: 75, tone: 85, confidence: 70)

        // Create 5 sessions
        for i in 0..<5 {
            _ = repository.createSession(
                scenarioId: "test-scenario",
                duration: TimeInterval(60 + i * 10),
                audioFileName: "session_\(i).m4a",
                scores: scores,
                coachNotes: [],
                tryAgainFocus: TryAgainFocus.default,
                metrics: AudioMetrics.empty
            )
        }

        // When: Getting visible sessions with free limit
        let allSessions = repository.sessions
        let freeLimit = 3

        // Then: Should have all 5 sessions total
        XCTAssertEqual(allSessions.count, 5)

        // Visible sessions should be limited
        let visibleSessions = Array(allSessions.prefix(freeLimit))
        XCTAssertEqual(visibleSessions.count, freeLimit)
    }

    // MARK: - Pro Status Transitions

    @MainActor
    func testUpgradeToProUnlocksFeatures() {
        // Given: Free user
        let gates = MockFeatureGates()
        gates.updateProStatus(false)

        XCTAssertFalse(gates.isPro)
        XCTAssertFalse(gates.hasUnlimitedHistory)
        XCTAssertFalse(gates.hasAdvancedFeedback)

        // When: User upgrades to Pro
        gates.updateProStatus(true)

        // Then: All features are unlocked
        XCTAssertTrue(gates.isPro)
        XCTAssertTrue(gates.hasUnlimitedHistory)
        XCTAssertTrue(gates.hasAdvancedFeedback)
    }

    @MainActor
    func testDowngradeFromProLocksFeatures() {
        // Given: Pro user
        let gates = MockFeatureGates()
        gates.updateProStatus(true)

        XCTAssertTrue(gates.isPro)

        // When: Subscription expires
        gates.updateProStatus(false)

        // Then: Features are locked again
        XCTAssertFalse(gates.isPro)
        XCTAssertFalse(gates.hasUnlimitedHistory)
        XCTAssertEqual(gates.maxVisibleSessions, 3)
    }

    // MARK: - Integration with Repository

    @MainActor
    func testProUserSeesAllSessionsInRepository() {
        // Given: Pro user with many sessions
        let gates = MockFeatureGates()
        gates.updateProStatus(true)

        let repository = MockSessionRepository()
        let scores = FeedbackScores(clarity: 80, pacing: 75, tone: 85, confidence: 70)

        // Create 10 sessions
        for i in 0..<10 {
            _ = repository.createSession(
                scenarioId: "test-scenario",
                duration: TimeInterval(60),
                audioFileName: "session_\(i).m4a",
                scores: scores,
                coachNotes: [],
                tryAgainFocus: TryAgainFocus.default,
                metrics: AudioMetrics.empty
            )
        }

        // When: Getting visible sessions
        let maxVisible = gates.maxVisibleSessions
        let visibleCount = min(repository.sessionCount, maxVisible)

        // Then: Pro user sees all sessions
        XCTAssertEqual(visibleCount, 10)
    }

    @MainActor
    func testFreeUserSeesLimitedSessionsInRepository() {
        // Given: Free user with many sessions
        let gates = MockFeatureGates()
        gates.updateProStatus(false)

        let repository = MockSessionRepository()
        let scores = FeedbackScores(clarity: 80, pacing: 75, tone: 85, confidence: 70)

        // Create 10 sessions
        for i in 0..<10 {
            _ = repository.createSession(
                scenarioId: "test-scenario",
                duration: TimeInterval(60),
                audioFileName: "session_\(i).m4a",
                scores: scores,
                coachNotes: [],
                tryAgainFocus: TryAgainFocus.default,
                metrics: AudioMetrics.empty
            )
        }

        // When: Getting visible sessions
        let maxVisible = gates.maxVisibleSessions
        let visibleCount = min(repository.sessionCount, maxVisible)

        // Then: Free user sees limited sessions
        XCTAssertEqual(visibleCount, 3)
    }
}

// MARK: - Scenario Access Tests

final class ScenarioAccessTests: XCTestCase {

    func testFreeAndProScenariosAreMutuallyExclusive() {
        // Given: All scenarios
        let freeScenarios = Scenario.freeScenarios
        let proScenarios = Scenario.proScenarios

        // Then: No overlap between free and pro
        let freeIds = Set(freeScenarios.map { $0.id })
        let proIds = Set(proScenarios.map { $0.id })

        XCTAssertTrue(freeIds.isDisjoint(with: proIds), "Free and Pro scenarios should not overlap")
    }

    func testAllScenariosAreCategorized() {
        // Given: All scenarios
        let allScenarios = Scenario.allScenarios
        let freeScenarios = Scenario.freeScenarios
        let proScenarios = Scenario.proScenarios

        // Then: Free + Pro = All
        XCTAssertEqual(
            freeScenarios.count + proScenarios.count,
            allScenarios.count,
            "All scenarios should be either free or pro"
        )
    }

    func testEachScenarioHasValidCategory() {
        // Given: All scenarios
        for scenario in Scenario.allScenarios {
            // Then: Each has a valid category
            let validCategories: [Scenario.Category] = [.boundaries, .career, .relationships, .difficult]
            XCTAssertTrue(validCategories.contains(scenario.category), "\(scenario.title) should have a valid category")
        }
    }
}
