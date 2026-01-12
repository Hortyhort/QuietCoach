// NavigationRoutingTests.swift
// QuietCoachTests
//
// Focused tests for routing state and pending entry points.

import XCTest
@testable import QuietCoach

final class NavigationRoutingTests: XCTestCase {

    @MainActor
    func testAppRouterConsumesPendingSession() {
        let router = AppRouter()
        let sessionId = UUID()

        router.enqueueSession(id: sessionId)

        XCTAssertEqual(router.consumePendingSessionId(), sessionId)
        XCTAssertNil(router.consumePendingSessionId())
    }

    @MainActor
    func testAppRouterRefreshesPendingRoutesFromUserDefaults() {
        let router = AppRouter()
        let scenarioId = Scenario.allScenarios.first?.id ?? "set-boundary"
        let sessionId = UUID()

        UserDefaults.standard.set(scenarioId, forKey: "pendingScenarioId")
        UserDefaults.standard.set(sessionId.uuidString, forKey: "pendingSessionId")

        defer {
            UserDefaults.standard.removeObject(forKey: "pendingScenarioId")
            UserDefaults.standard.removeObject(forKey: "pendingSessionId")
        }

        router.refreshPendingRoutes()

        XCTAssertEqual(router.consumePendingScenarioId(), scenarioId)
        XCTAssertEqual(router.consumePendingSessionId(), sessionId)
    }
}
