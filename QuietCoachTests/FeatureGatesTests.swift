// FeatureGatesTests.swift
// QuietCoachTests
//
// Unit tests for feature gating logic.

import XCTest
@testable import QuietCoach

final class FeatureGatesTests: XCTestCase {

    // MARK: - Mock Feature Gates Tests

    @MainActor
    func testMockFeatureGatesStartsAsFree() {
        let gates = MockFeatureGates()

        XCTAssertFalse(gates.isPro)
        XCTAssertTrue(gates.isLoaded)
    }

    @MainActor
    func testMockFeatureGatesCanBeSetToPro() {
        let gates = MockFeatureGates()

        gates.updateProStatus(true)

        XCTAssertTrue(gates.isPro)
        XCTAssertTrue(gates.hasUnlimitedHistory)
        XCTAssertTrue(gates.hasAdvancedFeedback)
    }

    @MainActor
    func testFreeUserHasLimitedSessionVisibility() {
        let gates = MockFeatureGates()
        gates.updateProStatus(false)

        XCTAssertEqual(gates.maxVisibleSessions, 3)
        XCTAssertFalse(gates.hasUnlimitedHistory)
    }

    @MainActor
    func testProUserHasUnlimitedSessionVisibility() {
        let gates = MockFeatureGates()
        gates.updateProStatus(true)

        XCTAssertEqual(gates.maxVisibleSessions, Int.max)
        XCTAssertTrue(gates.hasUnlimitedHistory)
    }

    @MainActor
    func testFreeUserCanAccessFreeScenarios() {
        let gates = MockFeatureGates()
        gates.updateProStatus(false)

        let freeScenario = Scenario.allScenarios.first { !$0.isPro }!
        XCTAssertTrue(gates.canAccessScenario(freeScenario))
    }

    @MainActor
    func testFreeUserCannotAccessProScenarios() {
        let gates = MockFeatureGates()
        gates.updateProStatus(false)

        let proScenario = Scenario.allScenarios.first { $0.isPro }
        if let proScenario {
            XCTAssertFalse(gates.canAccessScenario(proScenario))
        }
    }

    @MainActor
    func testProUserCanAccessAllScenarios() {
        let gates = MockFeatureGates()
        gates.updateProStatus(true)

        for scenario in Scenario.allScenarios {
            XCTAssertTrue(gates.canAccessScenario(scenario))
        }
    }
}

// MARK: - Scenario Tests

final class ScenarioTests: XCTestCase {

    func testAllScenariosHaveUniqueIds() {
        let ids = Scenario.allScenarios.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All scenarios should have unique IDs")
    }

    func testAllScenariosHaveNonEmptyTitles() {
        for scenario in Scenario.allScenarios {
            XCTAssertFalse(scenario.title.isEmpty, "Scenario \(scenario.id) should have a title")
        }
    }

    func testAllScenariosHaveNonEmptySubtitles() {
        for scenario in Scenario.allScenarios {
            XCTAssertFalse(scenario.subtitle.isEmpty, "Scenario \(scenario.id) should have a subtitle")
        }
    }

    func testAtLeastOneFreeScenarioExists() {
        let freeScenarios = Scenario.allScenarios.filter { !$0.isPro }
        XCTAssertGreaterThan(freeScenarios.count, 0, "Should have at least one free scenario")
    }
}
